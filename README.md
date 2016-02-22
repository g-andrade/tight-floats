

# tightfloats #

Copyright (c) 2016 Guilherme Andrade

__Version:__ 1.0.0

__Authors:__ Guilherme Andrade ([`tightfloats(at)gandrade(dot)net`](mailto:tightfloats(at)gandrade(dot)net)).

`tightfloats`: Bandwidth-friendly IEEE 754 floating-point serialisation for Erlang

---------


### <a name="What_is_it?">What is it?</a> ###


`tightfloats` is a lossy compression algorithm for [double precision floating-point values](https://en.wikipedia.org/wiki/Double-precision_floating-point_format). Its behaviour is adjusted through three parameters:
* `MinValue`, `MaxValue`: the range of the values (bigger range => more bits)
* `ErrorMargin`: a value, between 0 and 1, specifying how big do we want the error margin to be (bigger error margins => less bits)

It can achieve a **compression ratio of 5** when a 1% error margin and a range encompassing 6 orders of magnitude are specified.


### <a name="Show_me">Show me</a> ###


```erlang

MinValue = 0.1,     % 1.0e-1
MaxValue = 1000000, % 1.0e6
ErrorMargin = 0.05, % 5%
Packer = tfloats:packer(MinValue, MaxValue, ErrorMargin),
Unpacker = tfloats:unpacker(MinValue, MaxValue, ErrorMargin),

ValueA = 3.14,
PackedValueA = tfloats:pack(Packer, ValueA), % bit_size(PackedValue) == 10
tfloats:unpack(Unpacker, PackedValueA),      % [3.125]

ValueB = 3210,
PackedValueB = tfloats:pack(Packer, ValueB), % bit_size(PackedValue) == 10
tfloats:unpack(Unpacker, PackedValueB).      % [3200]

ValueC = 123000,
PackedValueC = tfloats:pack(Packer, ValueC), % bit_size(PackedValue) == 10
tfloats:unpack(Unpacker, PackedValueC).      % [122880]

```


### <a name="How_does_it_work?">How does it work?</a> ###


It chops up the original values into sign, exponent and significand parts and, based on the packing requirements, reduces the granularity of those values.


### <a name="TODO">TODO</a> ###


* Deal less ambiguously with mixed ranges (e.g. negative minimum value and positive maximum value.)
* Padding for easier use.


### <a name="Concerning_native_compilation_(HiPE)">Concerning native compilation (HiPE)</a> ###

Define 'COMPILE_NATIVE_TIGHTFLOATS' (e.g. "rebar compile -DCOMPILE_NATIVE_TIGHTFLOATS") for LOLSPEED™ in case that's your thing.


## Modules ##


<table width="100%" border="0" summary="list of modules">
<tr><td><a href="https://github.com/g-andrade/tight-floats/blob/master/doc/tfloats.md" class="module">tfloats</a></td></tr></table>

