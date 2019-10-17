CC = clang
CXX = clang++
BROWSER = web-browser
DMENU_APPEARANCE = -nb gray25 -nf orange -sf orange \
	-fn 'Noto Sans Mono-18' -m 0
EDITOR = vis
VISUAL = $EDITOR
http_proxy = http://localhost:8118/
https_proxy = http://localhost:8118/
LIBVIRT_DEFAULT_URI = qemu:///system
LS_COLORS = 'rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35'\
	^':bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43'\
	^':ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32'
NNTPSERVER = free.xsusenet.com
PARINIT = 'rTbgqR B=.,?_A_a Q=_s>|*-+ d1'
# GUI apps seem target to folks having excellent visual acuity and use
# tiny fonts to make room for the designers' artwork. I like to be able
# to read the text. These settings do not affect all GUI apps. Good luck.
let (gui_scale = 1.5; xscale = <=%xscale) {
	gui_scale = `($gui_scale*$xscale)
	QT_SCALE_FACTOR = $gui_scale
	GDK_DPI_SCALE = $gui_scale
}
