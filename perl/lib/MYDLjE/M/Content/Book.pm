package MYDLjE::M::Content::Book;
use MYDLjE::Base 'MYDLjE::M::Content';

has COLUMNS => sub {
  [ qw(
      id user_id pid alias keywords description tags
      data_type data_format time_created tstamp title
      body invisible language groups protected bad
      )
  ];
};
has WHERE => sub { {data_type => 'note'} };

1;

__END__

=head1 NAME

MYDLjE::M::Content::Book -  Content with data_type book
