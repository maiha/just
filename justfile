test: build
	cargo test --lib

# only run tests matching PATTERN
filter PATTERN: build
	cargo test --lib {{PATTERN}}

# test with backtrace
backtrace:
	RUST_BACKTRACE=1 cargo test --lib

build:
	cargo build

check:
	cargo check

watch COMMAND='test':
	cargo watch {{COMMAND}}

version = `sed -En 's/version[[:space:]]*=[[:space:]]*"([^"]+)"/v\1/p' Cargo.toml`

# publish to crates.io
publish: lint clippy test
	git branch | grep '* master'
	git diff --no-ext-diff --quiet --exit-code
	git co -b {{version}}
	git push github
	cargo publish
	git tag -a {{version}} -m {{version}}
	git push github --tags
	git push origin --tags
	@echo 'Remember to merge the {{version}} branch on GitHub!'

# clean up feature branch BRANCH
done BRANCH:
	git checkout {{BRANCH}}
	git pull --rebase github master
	git checkout master
	git pull --rebase github master
	git branch -d {{BRANCH}}

# push master to github as branch GITHUB-BRANCH
push GITHUB-BRANCH:
	git branch | grep '* master'
	git diff --no-ext-diff --quiet --exit-code
	git push github master:refs/heads/{{GITHUB-BRANCH}}

# install just from crates.io
install:
	cargo install -f just

# install development dependencies
install-dev-deps:
	rustup install nightly
	rustup update nightly
	rustup run nightly cargo install -f clippy
	cargo install -f cargo-watch
	cargo install -f cargo-check

# everyone's favorite animate paper clip
clippy:
	rustup run nightly cargo clippy

# count non-empty lines of code
sloc:
	@cat src/*.rs | sed '/^\s*$/d' | wc -l

lint:
	echo Checking for FIXME/TODO...
	! grep --color -En 'FIXME|TODO' src/*.rs
	echo Checking for long lines...
	! grep --color -En '.{100}' src/*.rs

nop:

fail:
	exit 1

backtick-fail:
	echo {{`exit 1`}}

test-quine:
	cargo run -- quine clean

# make a quine, compile it, and verify it
quine: create
	cc tmp/gen0.c -o tmp/gen0
	./tmp/gen0 > tmp/gen1.c
	cc tmp/gen1.c -o tmp/gen1
	./tmp/gen1 > tmp/gen2.c
	diff tmp/gen1.c tmp/gen2.c
	@echo 'It was a quine!'

quine-text = "int printf(const char*, ...); int main() { char *s = \"int printf(const char*, ...); int main() { char *s = %c%s%c; printf(s, 34, s, 34); return 0; }\"; printf(s, 34, s, 34); return 0; }"

# create our quine
create:
	mkdir -p tmp
	echo '{{quine-text}}' > tmp/gen0.c

# clean up
clean:
	rm -r tmp

# run all polyglot recipes
polyglot: python js perl sh ruby

python:
	#!/usr/bin/env python3
	print('Hello from python!')

js:
	#!/usr/bin/env node
	console.log('Greetings from JavaScript!')

perl:
	#!/usr/bin/env perl
	print "Larry Wall says Hi!\n";

sh:
	#!/usr/bin/env sh
	hello='Yo'
	echo "$hello from a shell script!"

ruby:
	#!/usr/bin/env ruby
	puts "Hello from ruby!"
