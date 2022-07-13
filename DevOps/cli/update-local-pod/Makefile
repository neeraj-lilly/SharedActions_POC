NAME=update-local-pod

all: debug
	./$(NAME) ../../../VirtualClaudia/ \
		--verbose \
		--git-hash 'OktaOidc: 1ecd792b4187912e5ec411f9514e059b60981769' \
		--input-filename './Assets/OktaOidcStateManager.swift' \
		--output-filename '../../../VirtualClaudia/Pods/OktaOidc/Okta/OktaOidc/OktaOidcStateManager.swift'

debug:
	swift build
	cp ./.build/debug/$(NAME) .

release:
	swift build -c release
	cp ./.build/release/$(NAME) .

clean:
	rm -rf $(NAME)
	rm -rf .build

doc:
	echo '# Usage' > USAGE.md
	echo >> USAGE.md
	echo '```' >> USAGE.md
	./$(NAME) --help >> USAGE.md
	echo '```' >> USAGE.md
