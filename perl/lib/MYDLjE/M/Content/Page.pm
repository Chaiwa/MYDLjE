package MYDLjE::M::Content::Page;
use MYDLjE::Base 'MYDLjE::M::Content';


has WHERE => sub { {data_type => 'page', deleted => 0} };


1;

__END__

=head1 NAME

MYDLjE::M::Content::Page -  basic content properties for my_pages objects

=head1 DESCRIPTION

TODO...
