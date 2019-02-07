
VERSION:= $(shell git log -1 --pretty='Commit:%h Date:%ci %an[%ae]')
PARAMS:="-DVERSION_INFO=\"${VERSION}\""

all: app

app: app.o
	gcc -o app app.o
app.o: app.c version.h
	gcc -o app.o -c app.c ${PARAMS}
clean:
	rm -f app app.o

.PHONY: all clean
