COMPONENT=RadioCountToLedsAppC
BUILD_EXTRA_DEPS = RadioCountMsg.py RadioCountMsg.class
CLEAN_EXTRA = RadioCountMsg.py RadioCountMsg.class RadioCountMsg.java

RadioCountMsg.py: RadioCountToLeds.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioCountMsg RadioCountToLeds.h JMES -o $@

RadioCountMsg.class: RadioCountMsg.java
	javac RadioCountMsg.java

RadioCountMsg.java: RadioCountToLeds.h
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=RadioCountMsg RadioCountToLeds.h JMES -o $@


include $(MAKERULES)

