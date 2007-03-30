dist:
	tar -czf syncha-`date +%Y%m%d`.tar.gz -C .. \
		--exclude=.svn --exclude=CVS --exclude='*.bak' --exclude='*~' \
		syncha/bin syncha/ena syncha/resolveZero syncha/mugicha syncha/README

dict:
	tar -czhf syncha-dict-`date +%Y%m%d`.tar.gz -C .. \
		--exclude=.svn --exclude=CVS --exclude='*.bak' --exclude='*~' \
		syncha/dict

.PHONY: dict
