use strict;
use warnings;
package Software::Security::Policy::Individual;

# VERSION

use parent 'Software::Security::Policy';
# ABSTRACT: The Individual Security Policy

use Data::Section -setup => { header_re => qr/\A__([^_]+)__\Z/ };
use Text::Template ();

sub name { 'individual' }

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Software::Security::Policy::Individual;

  my $policy = Software::Security::Policy::Individual->new({
    maintainer  => 'Timothy Legge <timlegge@gmail.com>',    # required
    program     => 'Software::Security::Policy',
    timeframe   => '7 days',
    url         => 'https://github.com/CPAN-Security/Software-Security-Policy/blob/main/SECURITY.md',
    perl_support_years   => '10',
  });

  print $policy->fulltext, "\n";

=head1 METHODS

=over

=item new

  my $policy = $subclass->new(\%arg);

This method returns a new security policy object for the given
security policy class.  Valid arguments are:

=back

=head2 ATTRIBUTES

=over

=item maintainer

the current maintainer for the distibrution; B<Required>

=item timeframe

the time to expect acknowledgement of a security issue.  Should
include the units such as '5 days or 2 weeks'; 

Default: 5 days

=item timeframe_quantity

the amount of time to expect an acknowledgement of a security issue.
Only used if timeframe is undefined and timeframe_units is defined
(eg. '5')

=item timeframe_units

the units of time to expect an acknowledgement of a security issue.
Only used if timeframe is undefined and timeframe_quantity is defined
(eg. 'days')

=item url

a url where the most current security policy can be found.

=item git_url

a git url where the most current security policy can be found.

=item perl_support_years

the number of years for which past major versions of Perl would be
supported

=item program

the name of software for use in the middle of a sentence

=item Program

the name of software for use in the beginning of a sentence

C<program> and C<Program> arguments may be specified both, either one or none.
Each argument, if not specified, is defaulted to another one, or to properly
capitalized "this program", if both arguments are omitted.

=back

=cut

sub new {
  my ($class, $arg) = @_;

  Carp::croak "no maintainer is specified" unless $arg->{maintainer};

  bless $arg => $class;
}

=method minimum_perl_version

The minimum version of perl that is supported.

=method perl_support_years

Get the number of years for which past major versions of Perl would be
supported.

=method timeframe

Get the expected response time. Defaults to 5 days and uses
timeframe_quantity and timeframe_units if the timeframe attribute
us undefined.

=method maintainer

Get the maintainer that should be contacted for security issues.

=method url

Get the URL of the latest security policy version.

These methods are attribute readers.

=cut

sub url { (defined $_[0]->{url} ? $_[0]->{url} :
            (defined $_[0]->{git_url} ? $_[0]->{git_url} :
                undef)) }

sub git_url { (defined $_[0]->{git_url} ? $_[0]->{git_url} :
            (defined $_[0]->{url} ? $_[0]->{url} :
                undef)) }


sub perl_support_years { $_[0]->{perl_support_years} };

sub minimum_perl_version { $_[0]->{minimum_perl_version} }

sub timeframe {
    return $_[0]->{timeframe} if defined $_[0]->{timeframe};
    return $_[0]->{timeframe_quantity} . ' ' . $_[0]->{timeframe_units}
        if defined $_[0]->{timeframe_quantity} &&
            defined $_[0]->{timeframe_units};
    return '5 days';
}

sub maintainer { $_[0]->{maintainer}     }

sub _dotless_maintainer {
  my $maintainer = $_[0]->maintainer;
  $maintainer =~ s/\.$//;
  return $maintainer;
}

=method program

Name of software for using in the middle of a sentence.

The method returns value of C<program> constructor argument (if it evaluates as true, i. e.
defined, non-empty, non-zero), or value of C<Program> constructor argument (if it is true), or
"this program" as the last resort.

Default: 'this program'

=cut

sub program { $_[0]->{program} || $_[0]->{Program} || 'this program' }

=method Program

Name of software for using at the beginning of a sentence.

The method returns value of C<Program> constructor argument (if it is true), or value of C<program>
constructor argument (if it is true), or "This program" as the last resort.

Default: 'This program'

=cut

sub Program { $_[0]->{Program} || $_[0]->{program} || 'This program' }

=method name

This method returns the name of the policy, suitable for shoving in the middle
of a sentence, generally with a leading capitalized "The."

=method url

This method returns the URL at which a canonical text of the security policy can be
found, if one is available.  If possible, this will point at plain text, but it
may point to an HTML resource.

=method git_url

This method returns the git URL at which a canonical text of the security policy can be
found, if one is available.  If possible, this will point at plain text, but it
may point to an HTML resource.

=method summary

This method returns a snippet of text, usually a few lines, indicating the
maintainer as well as an indication of the policy under which the software
is maintained.

=cut

sub summary { shift->_fill_in('SUMMARY') }

=method security_policy

This method returns the full text of the policy.

=cut

sub security_policy { shift->_fill_in('SECURITY-POLICY') }

=method fulltext

This method returns the complete text of the policy.

=cut

sub fulltext {
  my ($self) = @_;
  return join "\n", $self->summary, $self->security_policy;
}

=method version

This method returns the version of the policy.  If the security
policy is not versioned, this method will return undefined.

=cut

sub version  {
  my ($self) = @_;
  my $pkg = ref $self ? ref $self : $self;
  $pkg =~ s/.+:://;
  my (undef, @vparts) = split /_/, $pkg;

  return unless @vparts;
  return join '.', @vparts;
}

sub _fill_in {
  my ($self, $which) = @_;

  Carp::confess "couldn't build $which section" unless
    my $template = $self->section_data($which);

  return Text::Template->fill_this_in(
    $$template,
    HASH => { self => \$self },
    DELIMITERS => [ qw({{ }}) ],
  );
}

=head1 COPYRIGHT

This software is copyright (c) 2024-2025 by Timothy Legge <timlegge@gmail.com>.

This module is based extensively on Software::License.  Only the
changes required for this module are attributable to the author of
this module.  All other code is attributable to the author of
Software::License.

=cut

sub _perl_supported_version_section {
  my $self = shift;
  my $program = $self->program;
  if (my $minimum_perl_version = $self->minimum_perl_version) {
    return <<EOF;

Note that the $program project only supports major versions of Perl since
$minimum_perl_version, even though $program will run on
older versions of Perl. If a security fix requires us to increase
the minimum version of Perl that is supported, then we may do so.
EOF
  } elsif (my $perl_support_years = $self->perl_support_years) {
    return <<EOF

Note that the $program project only supports major versions of Perl
released in the past $perl_support_years years, even though $program will run on
older versions of Perl.  If a security fix requires us to increase
the minimum version of Perl that is supported, then we may do so.
EOF
  } else {
    return '';
  }
}
sub _latest_policy_location {
  my $self = shift;
  my $git_url = $self->git_url;
  my $program = $self->program;
  if (defined $git_url) {
    return <<EOF;

The latest version of the Security Policy can be found in the
[git repository for $program]($git_url).
EOF
  } else {
    return '';
  }
}
1;

__DATA__
__SUMMARY__
# Security Policy for the {{ $self->program }} distribution.

Report issues via email at: {{ $self->maintainer }}.

__SECURITY-POLICY__
This is the Security Policy for {{ $self->program }}.
{{ $self->_latest_policy_location }}
This text is based on the CPAN Security Group's Guidelines for Adding
a Security Policy to Perl Distributions (version 1.0.0)
https://security.metacpan.org/docs/guides/security-policy-for-authors.html

# How to Report a Security Vulnerability

Security vulnerabilities can be reported by e-mail to the current
project maintainers at {{ $self->maintainer }}.

Please include as many details as possible, including code samples
or test cases, so that we can reproduce the issue.  Check that your
report does not expose any sensitive data, such as passwords,
tokens, or personal information.

If you would like any help with triaging the issue, or if the issue
is being actively exploited, please copy the report to the CPAN
Security Group (CPANSec) at <cpan-security@security.metacpan.org>.

Please *do not* use the public issue reporting system on RT or
GitHub issues for reporting security vulnerabilities.

Please do not disclose the security vulnerability in public forums
until past any proposed date for public disclosure, or it has been
made public by the maintainers or CPANSec.  That includes patches or
pull requests.

For more information, see
[Report a Security Issue](https://security.metacpan.org/docs/report.html)
on the CPANSec website.

## Response to Reports

The maintainer(s) aim to acknowledge your security report as soon as
possible.  However, this project is maintained by a single person in
their spare time, and they cannot guarantee a rapid response.  If you
have not received a response from them within {{ $self->timeframe }}, then
please send a reminder to them and copy the report to CPANSec at
<cpan-security@security.metacpan.org>.

Please note that the initial response to your report will be an
acknowledgement, with a possible query for more information.  It
will not necessarily include any fixes for the issue.

The project maintainer(s) may forward this issue to the security
contacts for other projects where we believe it is relevant.  This
may include embedded libraries, system libraries, prerequisite
modules or downstream software that uses this software.

They may also forward this issue to CPANSec.

# Which Software This Policy Applies To

Any security vulnerabilities in {{ $self->program }} are covered by this policy.

Security vulnerabilities are considered anything that allows users
to execute unauthorised code, access unauthorised resources, or to
have an adverse impact on accessibility or performance of a system.

Security vulnerabilities in upstream software (embedded libraries,
prerequisite modules or system libraries, or in Perl), are not
covered by this policy unless they affect {{ $self->program }}, or {{ $self->program }} can
be used to exploit vulnerabilities in them.

Security vulnerabilities in downstream software (any software that
uses {{ $self->program }}, or plugins to it that are not included with the
{{ $self->program }} distribution) are not covered by this policy.

## Supported Versions of {{ $self->program }}

The maintainer(s) will only commit to releasing security fixes for
the latest version of {{ $self->program }}.
{{ $self->_perl_supported_version_section }}
# Installation and Usage Issues

The distribution metadata specifies minimum versions of
prerequisites that are required for {{ $self->program }} to work.  However, some
of these prerequisites may have security vulnerabilities, and you
should ensure that you are using up-to-date versions of these
prerequisites.

Where security vulnerabilities are known, the metadata may indicate
newer versions as recommended.

## Usage

Please see the software documentation for further information.
