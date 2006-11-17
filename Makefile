dist:
	tar -czf syncha-`date +%Y%m%d`.tar.gz -C .. \
		--exclude=.svn --exclude=CVS --exclude='*.bak' --exclude='*~' \
		syncha/bin syncha/ena syncha/resolveZero \
		syncha/sentence_splitter
