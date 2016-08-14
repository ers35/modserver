default:
	cd src && $(MAKE) all
run:
	cd src && $(MAKE) run
test:
	cd src && $(MAKE) test
install:
	cd src && $(MAKE) install
clean:
	cd src && $(MAKE) clean
modserver-git.zip:
	git archive HEAD --output $@
.PHONY: run test install clean modserver-git.zip
