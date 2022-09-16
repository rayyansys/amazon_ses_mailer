# AmazonSesMailer

This ruby gem allows you to use [Amazon SES](https://aws.amazon.com/ses/) API v2
to send emails from your Rails (or just Ruby) applications.
Email templates are hosted on Amazon Simple Email Service (SES) rather than the application.
This enables rapid development of templates, which can then be managed
by marketing teams, rather than engineering teams. The gem API is almost identical to
the [Rails ActionMailer](https://guides.rubyonrails.org/action_mailer_basics.html)
API to allow for easy integration/migration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'amazon_ses_mailer', github: 'rayyansys/amazon_ses_mailer'
```

And then execute:

    $ bundle

Note that this is still work in progress, that's why it is not released yet
on rubygems.org.
## Configuration

AWS credentials are automatically read by the underlying `aws-sdk-core` gem.
For more information, see the [aws-sdk-core documentation](https://github.com/aws/aws-sdk-ruby#configuration). Here is an example AWS IAM policy for the configured crednetials:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor1",
      "Effect": "Allow",
      "Action": [
        "ses:SendTemplatedEmail"
      ],
      "Resource": [
        "arn:aws:ses:<region>:<account_number>:template/*",
        "arn:aws:ses:<region>:<account_number>:identity/<identity_name>",
        "arn:aws:ses:<region>:<account_number>:configuration-set/<configuration_set_name1>",
        "arn:aws:ses:<region>:<account_number>:configuration-set/<configuration_set_name2>",
        "arn:aws:ses:<region>:<account_number>:contact-list/<contact_list_name>",
      ]
    }
  ]
}
```

## Usage


### Sending templated emails

As you would do with a regular `ActionMailer` subclass, you create a new mailer class,
but instead of inheriting from `ActionMailer::Base`, you would inherit from `AmazonSesMailer::Base`.

```ruby
class MyMailer < AmazonSesMailer::Base
  def welcome_email(email)
    mail(to: email, from_email: 'hello@example.org', from_name: 'Sender Name')
  end
end
```

This looks for a template on SES in the configured AWS region named `MyMailer-welcome_email`.
If found, it will be used to render the email and send it to the specified recipient.

### Merging dynamic content

If you want to merge dynamic content with the template, just set instance variables
as you would do with `ActionMailer`. Those variables will be converted to template
variables after stripping out the `@` character.

```ruby
class MyMailer < AmazonSesMailer::Base
  def welcome_email(user)
    @name = user.name
    @company = user.company

    mail(to: user.email,
         from_email: 'hello@example.org', from_name: 'Sender Name'
        )
  end
end
```

Alternatively, you can use the `merge_vars` parameter. Note that if this parameter
is specified, no instance variables will be converted. The below snippet is equivalent
to the previous one.

```ruby
class MyMailer < AmazonSesMailer::Base
  def welcome_email(user)
    mail(to: user.email,
         from_email: 'hello@example.org', from_name: 'Sender Name',
         merge_vars: {
           name: user.name,
           company: user.company
         }
        )
  end
end
```

Those variables will be merged with the template using the `{{Handlebars}}` syntax.
For more information about the syntax, see the
[SES documentation](https://docs.aws.amazon.com/ses/latest/dg/send-personalized-email-advanced.html).

#### Data types

This gem automatically transforms `nil` and `false` values to empty strings, and
applies some rules on merge variables.  Here is a summary for all supported data types:

| Type | Converted to | Example Input | Output |
| ---- | ------------ | ------------- | ------ |
| `NilClass` | Empty string | `nil` | `''` |
| `FalseClass` | Empty string | `false` | `''` |
| `String` | Same value | `'hello'` | `'hello'` |
| `Hash` | Hash with same keys with above rules applied recursively to values | `{a: false, b: 'hi'}` | `{a: '', b: 'hi'}` |
| `Array` | Array with same order with above rules applied recursively to items | `[false, 'hi', {a: 1}]` | `['', 'hi', {a: '1'}]` |
| All other types | calls `.to_s` on the value | `100` | `'100'` |

Note that the `Hash` type is useful when you want to use nested variables in your template.
For example, if your merge variables contain the following: `{person: {first_name: 'First', last_name: 'Last'}}`,
you can write in your template: `Hello {{person.first_name}} {{person.last_name}}`.

The `Array` type is also useful when you want to iterate on lists.
For example, if the merge variables have the following: `{contacts: [{name: 'person1'}, {name: 'person2'}]}`,
this can be in your template: `<ul>{{#each contacts}}<li>{{name}}</li>{{/each}}</ul>`

You should supply values for all the merge variables in the template,
even if they are empty strings. Otherwise, Amazon SES will throw a template rendering failure event.

If the template has an unsubscribe link placeholder, you must supply the contact list name in the parameters.

### Setting defaults

If you have multiple methods in the same mailer class, you may find it convenient to use the `default` DSL:

```ruby
class MyMailer < AmazonSesMailer::Base
  default from_email: 'hello@example.com', from_name: 'Sender Name'

  def welcome_email(user)
    mail(to: user.email)
  end

  def confirmation_email(user)
    mail(to: user.email)
  end
end
```

### Parameter Reference

Here is a list of all supported parameters that can be used in either the `mail`
method or the `default` DSL:

| Parameter  | Description |
| -----------|-------------|
| `from_name` | The name of the sender |
| `from_email` | The email address of the sender (must be verified on the AWS console) |
| `to` | A string or an array of strings representing the email addresses of the recipients appearing in the `To:` field |
| `reply_to` | A string or an array of strings representing the email addresses of the recipients appearing in the `Reply-To:` field. Defaults to `nil` |
| `template` | Template name to use for rendering the email. Defaults to the name of the mailer class method invoking the `mail` method |
| `merge_vars` | Hash of variables to merge into the template. If this parameter is omitted, all instance variables will be converted to merge variables |
| `configuration_set_name` | The SES configuration set to use for sending the email. If not specified, the default SES configuration set will be used (defined in the AWS console) |
| `contact_list_name` | The contact list to use for sending the email. Required if the template contains an unsubscribe link placeholder |
| `topic_name` | The topic name to use for sending the email to the above contact list. If ommitted, the unsubscribe link will unsubscribe from all topics when used as an email header |

Note that the email subject is defined in the template itself and does not have
a separate parameter in the SES API. If you want to use dynamic subjects, you can
pass a merge variable (e.g. `subject`) and use it in the subject line: `{{subject}}`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

When running tests, you should enable the test mode to skip deliveries
and accumulate messages in a testable array instead:

```ruby
AmazonSesMailer::Base.delivery_method = :test
```

In a rails application, typically this should go `config/environments/test.rb`.

If you want to verify simulated deliveries, you do the same you would do with `ActionMailer`,
except replacing `ActionMailer::Base` with `AmazonSesMailer::Base`:

```ruby
describe ".welcome_email" do
  it { expect{ MyMailer.welcome_email(user).deliver }
            .to change{ AmazonSesMailer::Base.deliveries.count }.by(1) }
end
```

You can also verify the raw API call input by inspecting the `deliveries` array:

```ruby
describe ".welcome_email" do
  it {
    MyMailer.welcome_email(user).deliver
    delivery = AmazonSesMailer::Base.deliveries.last
    Rails.logger.debug(delivery) # to print the delivery object
    expect(delivery.template).to eq("MyMailer-welcome_email") # this is added to the delivery
    expect(delivery.from_email_address).to eq("Sender Name <hello@example.org>")
    ...
  }
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rayyansys/amazon_ses_mailer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
