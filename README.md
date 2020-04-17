# CSErrors

A set of additions to `Error`, `CocoaError`, and `URLError` which provide some handy features:

- Easily make an `Error` from a POSIX error code or an `OSStatus`.
- Easily find out whether an `Error` represents a file not found error, a permissions error, or a cancellation error, regardless of the error's domain.
- Easily wrap any `Error` in a `RecoverableError` to present recovery options in error dialogs.
- Quickly and easily create a `CocoaError` or a `URLError` containing any of their supported `userInfo` dictionary keys.

These additions are free for any use.

Charles Srstka
