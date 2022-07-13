NAME=release-archive

all: debug
	mkdir -p output

	#./$(NAME) usVendorQA --verbose
	./$(NAME) LillyTogetherUSInternalQA --verbose \
		--profile-root ../../../.github/secrets \
		--project-path ../../../VirtualClaudia/ \
		--export-plist plist/export-options-development.plist \
		--mock-archive \
		#--release-version 1.2.3 \
		--release-summary 'From makefile test only' \
		--release-build "2" \
		--previous-release 'LillyTogetherUSIVT_v8.0.0(14)_IV' \
		--dry-run \
		--export-plist plist/export-options-development.plist \

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
		Sources/ArchiveRelease/

clean:
	rm -rf $(NAME)
	rm Package.resolved
	rm -rf .build
