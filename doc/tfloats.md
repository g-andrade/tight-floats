

# Module tfloats #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)



<a name="types"></a>

## Data Types ##




### <a name="type-error_margin">error_margin()</a> ###



<pre><code>
error_margin() = float()
</code></pre>



 bigger or equal to 0, less than 1



### <a name="type-packer">packer()</a> ###



<pre><code>
packer() = #tightfloats{}
</code></pre>





### <a name="type-tfloat">tfloat()</a> ###



<pre><code>
tfloat() = &lt;&lt;_:1, _:_*1&gt;&gt;
</code></pre>





### <a name="type-unpacker">unpacker()</a> ###



<pre><code>
unpacker() = #tightfloats{}
</code></pre>


<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#pack-2">pack/2</a></td><td></td></tr><tr><td valign="top"><a href="#packer-3">packer/3</a></td><td></td></tr><tr><td valign="top"><a href="#unpack-2">unpack/2</a></td><td></td></tr><tr><td valign="top"><a href="#unpacker-3">unpacker/3</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="pack-2"></a>

### pack/2 ###


<pre><code>
pack(Packer::<a href="#type-packer">packer()</a>, ValueOrValues::number() | [number()]) -&gt; <a href="#type-tfloat">tfloat()</a>
</code></pre>

<br></br>



<a name="packer-3"></a>

### packer/3 ###


<pre><code>
packer(MinValue::number(), MaxValue::number(), ErrorMargin::<a href="#type-error_margin">error_margin()</a>) -&gt; <a href="#type-packer">packer()</a>
</code></pre>

<br></br>



<a name="unpack-2"></a>

### unpack/2 ###


<pre><code>
unpack(Unpacker::<a href="#type-unpacker">unpacker()</a>, PackedValues::bitstring()) -&gt; [float()]
</code></pre>

<br></br>



<a name="unpacker-3"></a>

### unpacker/3 ###


<pre><code>
unpacker(MinValue::number(), MaxValue::number(), ErrorMargin::<a href="#type-error_margin">error_margin()</a>) -&gt; <a href="#type-unpacker">unpacker()</a>
</code></pre>

<br></br>



