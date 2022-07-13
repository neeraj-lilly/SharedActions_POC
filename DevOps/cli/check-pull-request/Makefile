NAME=check-pull-request

all: debug
	./$(NAME) ../../../VirtualClaudia/ --verbose --enable-xcpretty --pr-title "LDV-123 this is a PR" --simulator-name "iPhone 12" --simulator-os "14.2"
	# ./$(NAME) ../../../VirtualClaudia/ --verbose --skip-unit-tests --pr-title "LDV-123 this is a PR" --simulator-name "iPhone 12" --simulator-os "14.2"
	# ./$(NAME) . --pr-title "LDV-a123 this is a PR" --branch-name "feature/LDV-123-mock-pr"
	# ./$(NAME) . --pr-title "LDV-a123 this is a PR" --branch-name "feature/LDV-a123-mock-pr"

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
