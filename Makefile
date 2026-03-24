.PHONY: serve build clean new

serve:
	hugo server -D --buildFuture

build:
	hugo --minify

clean:
	rm -rf public resources

new:
	@read -p "Slug: " slug; \
	hugo new content posts/$$(date +%Y-%m-%d)-$$slug.md
