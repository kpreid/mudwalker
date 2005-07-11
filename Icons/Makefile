RASTERIZE = java -jar /Stuff/batik-1.5/batik-rasterizer.jar -dpi 72 

.SUFFIXES: .icns -intermediate-32.png .png

%.icns: %-intermediate-32.png
	$(BUILT_PRODUCTS_DIR)/mw_icnstool $*

%-intermediate-32.png: %.svg
	for size in 16 32 48 128 ; do \
	  $(RASTERIZE) -w $${size} -h $${size} -d $*-intermediate-$${size}.png $< ;\
	done

%.png: %.svg
	$(RASTERIZE) $<

all: \
  mwapp.icns \
  mwdoc.icns \
  TB_selectHistoryFirst.png \
  TB_selectHistoryPrev.png \
  TB_selectHistoryNext.png \
  TB_selectHistoryLast.png \
  TB_mwOpenConnection.png \
  TB_mwCloseConnectionHard.png \
  TB_mwCloseConnectionNice.png \
  TB_mwUnlinkWindow.png \
  TB_mwOpenDocumentSettings.png \
  TB_mwSendPing.png \
  TB_mwClearScrollback.png \
  TB_mwModeMain.png \
  TB_mwModePassword.png

clean:
	rm -f *.png
	rm -f *.icns
