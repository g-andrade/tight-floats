-module(tfloats).
-author('Guilherme Andrade <tightfloats(at)gandrade(dot)net>').

-ifdef(COMPILE_NATIVE_TIGHTFLOATS).
% LOLSPEED ™
-compile([inline, inline_list_funcs, native, {hipe, o3}]).
-else.
-compile([inline, inline_list_funcs]).
-endif.

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([packer/3]).   -ignore_xref([{packer, 3}]).
-export([pack/2]).     -ignore_xref([{pack, 2}]).
-export([unpacker/3]). -ignore_xref([{unpacker, 3}]).
-export([unpack/2]).   -ignore_xref([{unpack, 2}]).

%% ------------------------------------------------------------------
%% Macro Definitions
%% ------------------------------------------------------------------

% https://en.wikipedia.org/wiki/Double-precision_floating-point_format
%
-define(IEEE754_DBL_SIGN_BS, 1).
-define(IEEE754_DBL_EXPON_BS, 11).
-define(IEEE754_DBL_SIGNIF_BS, 52).

%% ------------------------------------------------------------------
%% Record Definitions
%% ------------------------------------------------------------------

-record(tightfloats, {
          minimum :: {Exponent :: non_neg_integer(), Significand :: non_neg_integer()},
          maximum :: {Exponent :: non_neg_integer(), Significand :: non_neg_integer()},
          sign_info :: sign_info(),
          exponent_bitsize :: non_neg_integer(),
          significand_bitsize :: pos_integer(),
          serialised_bitsize :: pos_integer()
         }).
-type packer() :: #tightfloats{}.
-type unpacker() :: #tightfloats{}.

%% ------------------------------------------------------------------
%% Type Definitions
%% ------------------------------------------------------------------

-type sign() :: 0 | 1.
-type exponent() :: 0..16#7FF. % ((1 bsl 11) - 1).
-type significand() :: 0..16#FFFFFFFFFFFFF. % ((1 bsl 52) - 1).
-type sign_info() :: negative | positive | network.

-type error_margin() :: float(). % bigger or equal to 0, less than 1
-export_type([error_margin/0]).

-type tfloat() :: <<_:1,_:_*1>>.
-export_type([tfloat/0]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

-spec packer(MinValue :: number(), MaxValue :: number(), ErrorMargin :: error_margin())
        -> packer().
packer(MinValue, MaxValue, ErrorMargin) ->
    new_tightfloats(MinValue, MaxValue, ErrorMargin).

-spec pack(Packer :: packer(), ValueOrValues :: number() | [number()]) -> tfloat().
pack(Packer, Values) when is_list(Values) ->
    pack_multiple(Packer, Values);
pack(Packer, Value) ->
    pack_single(Packer, Value).

-spec unpacker(MinValue :: number(), MaxValue :: number(), ErrorMargin :: error_margin())
        -> unpacker().
unpacker(MinValue, MaxValue, ErrorMargin) ->
    new_tightfloats(MinValue, MaxValue, ErrorMargin).

-spec unpack(Unpacker :: unpacker(), PackedValues :: bitstring()) -> [float()].
unpack(_Unpacker, <<>>=_PackedValues) ->
    [];
unpack(Unpacker, PackedValues) ->
    SerialisedBitsize = Unpacker#tightfloats.serialised_bitsize,
    <<PackedValue:SerialisedBitsize/bitstring, NextPackedValues/bitstring>> = PackedValues,
    [unpack_single(Unpacker, PackedValue) | unpack(Unpacker, NextPackedValues)].

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

-spec new_tightfloats(MinValue :: number(), MaxValue :: number(), ErrorMargin :: error_margin())
        -> packer().
new_tightfloats(MinValue, MaxValue, ErrorMargin) when MaxValue > MinValue, MinValue /= 0, MaxValue /= 0 ->
    {_MinV_Sign, MinV_Exponent, MinV_Significand} = disassemble_ieee754_double(MinValue),
    {_MaxV_Sign, MaxV_Exponent, MaxV_Significand} = disassemble_ieee754_double(MaxValue),
    SignInfo = sign_info(MinValue, MaxValue),
    ExponentBitsize = minimum_bits_for(MaxV_Exponent - MinV_Exponent),
    SignificandBitSize = significand_bitsize(ErrorMargin),
    SerialisedBitsize = serialised_bitsize(SignInfo, ExponentBitsize, SignificandBitSize),
    #tightfloats{minimum = {MinV_Exponent, MinV_Significand},
                 maximum = {MaxV_Exponent, MaxV_Significand},
                 exponent_bitsize = ExponentBitsize,
                 significand_bitsize = SignificandBitSize,
                 sign_info = SignInfo,
                 serialised_bitsize = SerialisedBitsize}.

-spec pack_multiple(Packer :: packer(), Values :: [number()]) -> tfloat().
pack_multiple(Packer, Values) ->
    lists:foldl(
      fun (Value, Acc) ->
              PackedValue = pack_single(Packer, Value),
              <<Acc/bitstring, PackedValue/bitstring>>
      end,
      <<>>,
      Values).

-spec pack_single(Packer :: packer(), Value :: number()) -> tfloat().
pack_single(Packer, Value) ->
    #tightfloats{minimum = {MinV_Exponent, MinV_Significand},
                 maximum = {MaxV_Exponent, MaxV_Significand},
                 exponent_bitsize = ExponentBitsize,
                 significand_bitsize = SignificandBitSize,
                 sign_info = SignInfo} = Packer,

    {Sign, Exponent, Significand} = disassemble_ieee754_double(Value),
    {ProcessedExponent, ProcessedSignificand} =
    if Exponent < MinV_Exponent ->
           {MinV_Exponent, MinV_Significand};
       Exponent > MaxV_Exponent ->
           {MaxV_Exponent, MaxV_Significand};
       Exponent =:= MaxV_Exponent ->
           {Exponent, min(Significand, MaxV_Significand)};
       Exponent =:= MinV_Exponent ->
           {Exponent, max(Significand, MinV_Significand)};
       true ->
           {Exponent, Significand}
    end,

    SerialisedExponent = ProcessedExponent - MinV_Exponent,
    SerialisedSignificand = ProcessedSignificand bsr (?IEEE754_DBL_SIGNIF_BS - SignificandBitSize),
    SignBitsize = sign_bitsize(SignInfo),
    <<Sign:SignBitsize, SerialisedExponent:ExponentBitsize, SerialisedSignificand:SignificandBitSize>>.

-spec unpack_single(Unpacker :: unpacker(), PackedValue :: tfloat()) -> float().
unpack_single(Unpacker, PackedValue) ->
    #tightfloats{minimum = {MinV_Exponent, _MinV_Significand},
                 exponent_bitsize = ExponentBitsize,
                 significand_bitsize = SignificandBitSize,
                 sign_info = SignInfo} = Unpacker,

    SignBitsize = sign_bitsize(SignInfo),
    <<SerialisedSign:SignBitsize, SerialisedExponent:ExponentBitsize,
      SerialisedSignificand:SignificandBitSize>> = PackedValue,

    Sign = case SignInfo of
               network  -> SerialisedSign;
               positive -> 0;
               negative -> 1
           end,
    Exponent = SerialisedExponent + MinV_Exponent,
    Significand = SerialisedSignificand bsl (?IEEE754_DBL_SIGNIF_BS - SignificandBitSize),
    assemble_ieee754_double(Sign, Exponent, Significand).

-spec sign_info(MinValue :: number(), MaxValue :: number()) -> sign_info().
sign_info(MinValue, MaxValue) when MinValue < 0, MaxValue > 0 ->
    network;
sign_info(MinValue, MaxValue) when MinValue < 0, MaxValue < 0 ->
    negative;
sign_info(MinValue, MaxValue) when MinValue > 0, MaxValue > 0 ->
    positive.

-spec sign_bitsize(SignInfo :: sign_info()) -> 0 | 1.
sign_bitsize(network)   -> 1;
sign_bitsize(_SignInfo) -> 0.

-spec significand_bitsize(error_margin()) -> 1..52.
significand_bitsize(ErrorMargin) when ErrorMargin == 0 ->
    ?IEEE754_DBL_SIGNIF_BS;
significand_bitsize(ErrorMargin) when ErrorMargin >= 0, ErrorMargin < 1 ->
    MarginValue = (1 bsl ?IEEE754_DBL_SIGNIF_BS) * ErrorMargin,
    MarginBitsize = trunc(math:log(MarginValue) / math:log(2)),
    max(1, min(?IEEE754_DBL_SIGNIF_BS, ?IEEE754_DBL_SIGNIF_BS - MarginBitsize)).

-spec serialised_bitsize(sign_info(),
                         ExponentBitsize :: 1..11,
                         SignificandBitSize :: 1..52) -> pos_integer().
serialised_bitsize(network, ExponentBitsize, SignificandBitSize) ->
    1 + ExponentBitsize + SignificandBitSize;
serialised_bitsize(_, ExponentBitsize, SignificandBitSize) ->
    ExponentBitsize + SignificandBitSize.

-spec disassemble_ieee754_double(Value :: number()) -> {sign(), exponent(), significand()}.
disassemble_ieee754_double(Value) ->
    <<Sign:?IEEE754_DBL_SIGN_BS, Exponent:?IEEE754_DBL_EXPON_BS,
      Significand:?IEEE754_DBL_SIGNIF_BS>> = <<Value/float>>,
    {Sign, Exponent, Significand}.

-spec assemble_ieee754_double(sign(), exponent(), significand()) -> float().
assemble_ieee754_double(Sign, Exponent, Significand) ->
    <<Value/float>> = <<Sign:?IEEE754_DBL_SIGN_BS, Exponent:?IEEE754_DBL_EXPON_BS,
                        Significand:?IEEE754_DBL_SIGNIF_BS>>,
    Value.

-spec minimum_bits_for(number()) -> non_neg_integer().
minimum_bits_for(V) ->
    ceil(math:log(V) / math:log(2)).

-spec floor(float()) -> integer().
floor(V) when V < 0 ->
    trunc(V) - 1;
floor(V) ->
    trunc(V).

-spec ceil(float()) -> integer().
ceil(V) -> floor(V) + 1.
