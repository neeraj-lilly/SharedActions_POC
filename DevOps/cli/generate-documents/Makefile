NAME=generate-documents

all: debug
	mkdir -p output
	# ./$(NAME)
	./$(NAME) \
		--project-path ../../../VirtualClaudia/VirtualClaudia.xcodeproj/ \
		--core-data-path ../../../VirtualClaudia/VirtualClaudia/Classes/CoreData/VirtualClaudia.xcdatamodeld/ \
		--podfile-path ../../../VirtualClaudia/ \
		--css-filename style.css \
		--additional-license-owner 'Phosphor Icons' \
		--additional-license-filename 'assets/phosphor-icons.license' \
		--output-path ../../../Documents/Automated

		# --output-path output

debug: dependency
	swift build
	cp ./.build/debug/$(NAME) .

release: dependency
	swift build -c release
	cp ./.build/release/$(NAME) .

dependency:
	cp -f \
		../../../VirtualClaudia/VirtualClaudia/Sources/Shared/ReleaseType/ReleaseType.swift \
		../../../VirtualClaudia/VirtualClaudia/Sources/Shared/ReleaseType/ReleaseType+Xcode.swift \
		Sources/DocumentGenerator/

clean:
	rm -rf $(NAME)
	rm Package.resolved
	rm -rf .build
