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
Note that you should supply values for all the merge variables in the template,
even if they are empty strings. Otherwise, Amazon SES will throw a template rendering failure event.
This gem automatically converts all values to strings and transforms `nil` and `false`
values to empty strings.
If the template has an unsubscribe link placeholder, you must supply the contact list name in the parameters.

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

Here is a list of all supported parameters that can be used in either the `mail`
method or the `default` DSL:

- `from_name`: The name of the sender.
- `from_email`: The email address of the sender (must be verified on the AWS console).
- `to`: A string or an array of strings representing the email addresses of the recipients appearing in the `To:` field.
- `reply_to`: A string or an array of strings representing the email addresses of the recipients appearing in the `Reply-To:` field. Defaults to `nil`.
- `template`: Template name to use for rendering the email. Defaults to the name of the mailer class method invoking the `mail` method.
- `merge_vars`: Hash of variables to merge with the template. All keys with falsey values (`nil` or `false`) will be converted to empty strings. All truthy values will be converted to strings.
If this parameter is omitted, all instance variables will be converted to merge variables.
- `configuration_set_name`: The SES configuration set to use for sending the email. If not specified, the default SES configuration set will be used (defined in the AWS console).
- `contact_list_name`: The contact list to use for sending the email. Required if the template contains an unsubscribe link placeholder.
- `topic_name`: The topic name to use for sending the email to the above contact list. If ommitted, the unsubscribe link will unsubscribe from all topics when used as an email header.

Note that the email subject is defined in the template itself.
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing

When writing tests, you should mock the SES API call. If using rspec:

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.before(:each) do |e|
    allow_any_instance_of(::Aws::SESV2::Client).to receive(:send_email).and_return({message_id: '123'})
  end
end
```

If you want to verify deliveries, you do the same you would do with `ActionMailer`,
except replacing `ActionMailer::Base` with `AmazonSesMailer::Base`:

```ruby
describe ".welcome_email" do
  it { expect{ MyMailer.welcome_email(user).deliver }
            .to change{ AmazonSesMailer::Base.deliveries.count }.by(1) }
end
```

You can also verify the raw API call input and (mocked) output by inspecting
the `deliveries` array:

```ruby
describe ".welcome_email" do
  it {
    MyMailer.welcome_email(user).deliver
    delivery = AmazonSesMailer::Base.deliveries.last
    Rails.logger.debug(delivery) # to print the delivery object
    expect(delivery.template).to eq("MyMailer-welcome_email") # this is added to the delivery
    expect(delivery.from_email_address).to eq("Sender Name <hello@example.org>")
    expect(delivery.message_id).to eq("123") # this is added to the delivery
    ...
  }
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rayyansys/amazon_ses_mailer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
