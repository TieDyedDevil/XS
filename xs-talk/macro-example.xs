fn mf {|name thunk|
	fn $name {|*|
		{$thunk $*}
		echo 'made by mf'
	}
}

mf b '{echo bbb}'
b

mf c '{|n| echo `($n+7)}'
c 5
