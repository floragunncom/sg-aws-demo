.PHONY: all init clean

all: bootstrap.zip

bootstrap.zip: target/bootstrap.min.json
	zip -jr $@ target/*

target/bootstrap.min.json: target/bootstrap.json
	jq -c . < $< >$@

target/bootstrap.json: init src/*.py
	python src/main.py > $@

init:
	mkdir -p target

clean:
	rm -rf bootstrap.zip target src/*.pyc
