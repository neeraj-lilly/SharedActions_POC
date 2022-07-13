NAME=update-market-resource

all: clean debug
	# ./$(NAME) ConfigUnknown --project-path ../../../VirtualClaudia/
	# ./$(NAME) DebugLillyTogetherBRQA --project-path ../../../VirtualClaudia/
	./$(NAME) DebugLillyTogetherUSQA --project-path ../../../VirtualClaudia/

debug:
	swift build
	cp ./.build/debug/$(NAME) .

release:
	swift build -c release
	cp ./.build/release/$(NAME) .

clean:
	rm -rf $(NAME)
