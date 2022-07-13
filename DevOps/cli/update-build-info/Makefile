NAME=update-build-info

all: clean debug
	./$(NAME)

update: clean release
	./$(NAME) update --project-path ../../../VirtualClaudia/ --file-path VirtualClaudia/Sources/Shared/Generated/BuildInfo.swift

revert: clean release
	./$(NAME) revert --project-path ../../../VirtualClaudia/ --file-path VirtualClaudia/Sources/Shared/Generated/BuildInfo.swift

debug:
	swift build
	cp ./.build/debug/$(NAME) .

release:
	swift build -c release
	cp ./.build/release/$(NAME) .

clean:
	rm -rf $(NAME)
