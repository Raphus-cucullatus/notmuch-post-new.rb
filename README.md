# Notmuch post-new (tagging) using Ruby.

[Notmuch](https://notmuchmail.org) is an email indexing system.  For customized email tagging and user-defined automation, notmuch runs the `post-new` [hooks](https://notmuchmail.org/manpages/notmuch-hooks-5/) script.

This repository provides some helpers to write such script in Ruby as well as an in-used example.

## Example

To add "sent" tag to those emails that sent FROM one of my email
addresses but not TO one of my email addresses, one can use:

```ruby
mark_sent_expr = And.new(Or.new(*(My_mail_addrs.map {|addr| From.new(addr)})),
                         Not.new(Or.new(*(My_mail_addrs.map {|addr| To.new(addr)}))))

NotmuchTagCommand.new(
  %w(sent),
  %w(inbox unread),
  mark_sent_expr
).run
```

This translates to the notmuch command below:

```sh
notmuch tag +sent -inbox -unread  '(' from:addr1 or from:addr2 ')'  and not  '(' to:addr1 to:addr2 ')'
```

See [post-new-example-mac](./post-new-example-mac) for a concrete example and [notmuch.rb](./notmuch.rb) for details.
