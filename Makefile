all: apfview.d64

apfview.prg: apf.s
	dasm apf.s -f1 -oapfview.prg -lapf.l

apfview.d64: apfview.prg
	c1541 -format "comb. lemons,22" d64 apfview.d64 \
	-write apfview.prg apfview \
	-write data/charset \
	-write data/aperture.apf \
	-write data/aperture.amf \
	-write data/sign.apf \
	-write data/sign.amf

clean:
	rm -f apf.l apfview.prg apfview.d64

