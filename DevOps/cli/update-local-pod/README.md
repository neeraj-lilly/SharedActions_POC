# Local Pod Updater

Example: add this in `Podfile`:

```ruby
post_install do |pi|
    # ...
    # Update local pods
    cmd = <<-eos
        ../DevOps/cli/update-local-pod/update-local-pod ./ \
            --git-hash 'OktaOidc: 1ecd792b4187912e5ec411f9514e059b60981769' \
            --input-filename '../DevOps/cli/update-local-pod/Assets/OktaOidcStateManager.swift' \
            --output-filename './Pods/OktaOidc/Okta/OktaOidc/OktaOidcStateManager.swift'
    eos
    system(cmd) or raise "Error: update-local-pod failed, please contact tech leads at #digh-lillyplus-dev on slack."
end
```
