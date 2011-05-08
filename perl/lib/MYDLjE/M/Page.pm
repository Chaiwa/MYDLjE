package MYDLjE::M::Page;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();
use MYDLjE::M::Content;

has TABLE => 'my_pages';

has COLUMNS => sub {
  [ qw(
      id pid alias page_type sorting template
      cache expiry permissions user_id group_id
      tstamp start stop published hidden deleted changed_by
      )
  ];
};

my $id_regexp = {regexp => qr/^\d+$/x};

has FIELDS_VALIDATION => sub {
  my $self  = shift;
  my %alias = $self->FIELD_DEF('alias32');
  $alias{alias} = $alias{alias32};
  delete $alias{alias32};
  return {
    $self->FIELD_DEF('id'),
    $self->FIELD_DEF('pid'),
    %alias,
    page_type => {
      required    => 1,
      constraints => [{in => ['regular', 'root', 'folder']},]
    },
    $self->FIELD_DEF('sorting'),
    cache  => {regexp => qr/^[01]$/x,},
    expiry => {regexp => qr/^\d{1,6}$/x,},
    $self->FIELD_DEF('permissions'),
    $self->FIELD_DEF('user_id'),
    $self->FIELD_DEF('group_id'),
    published => {regexp => qr/^[012]$/x},
    $self->FIELD_DEF('cache'),
    $self->FIELD_DEF('deleted'),
    $self->FIELD_DEF('hidden'),
    $self->FIELD_DEF('changed_by'),
  };
};

*tstamp = \&MYDLjE::M::Content::tstamp;
*start  = \&MYDLjE::M::Content::start;
*stop   = \&MYDLjE::M::Content::stop;

sub add {
  my ($class, $args) = MYDLjE::M::get_obj_args(@_);
  ($class eq __PACKAGE__)
    || Carp::croak(
    'Call this method only like: ' . __PACKAGE__ . '->add(%args);');

#todo
  my $page = __PACKAGE__->new;
  return $page;
}

1;


__END__

=encoding utf8

=head1 NAME

MYDLjE::M::Page - MYDLjE::M-based Page class

=head1 SYNOPSIS

  my $home_page = MYDLjE::M::Page->select(alias=>'home');

=head1 DESCRIPTION

This class is used to instantiate page objects. 

=head1 ATTRIBUTES

This class inherits all attributes from MYDLjE::M and overrides the ones listed below.

Note also that all table-columns are available as setters and getters for the instantiated object.



=head2 COLUMNS

Retursns an ARRAYREF with all columns from table C<my_pages>.  These are used to automatically generate getters/setters.

=head2 TABLE

Returns the table name from which rows L<MYDLjE::M::Page> instances are constructed: C<my_pages>.


=head2 FIELDS_VALIDATION

Returns a HASHREF with column-names as keys and L<MojoX::Validator> constraints used in the getters/setters when retreiving and inserting values. See below.

=head1 DATA ATTRIBUTES

=head2 id

Primary key.

=head2 pid

Parent id - foreing key referencing the page under which this page is found in the site structure.

=head2 alias

Unique seo-friendly alias used to construct the url pointing to this page

=head2 page_type

In MYDLjE there are  several types of pages:

    "folder" - not displayed in the front-end/site - used just as parent of 
        a list of items possibly stored in other tables.
     "regular" - regular pages are used to construct menus in the site 
        and to display content or front-end modules/widgets implemented as TT/TA Plugins
     "root" - a page representing the root of a site

Other types of pages can be added easily and used depending on the business logic you define.

=head2 sorting

Used to set the order of the pages under the same L</pid>

=head2 template

TT/TA code to display this page. Default template for pages in the site is used 
if this field is empty.

=head2 cache

Should this page be cached by the browser? 1=yes, 0=no

=head2 expiry

After how many seconds this page will expire when C<cache=1>? Default: 86400 = 24 hours. 

=head2 permissions

This field represents permissions for the curent page very much like permissions 
of a file. The format is "duuugggoo" where first "d" or "-" is for 
"Is this page a container for other items?" it is set for the first time when a child record 
from some table is attached to this page. "u" represents permissions for the owner of the page.
Valid values are "r", "w", "x" and "-".  The last triple is for the rest of the users.

=head2 user_id

Id of the owner of the page. Usually the user that creates the page.

=head2 group_id

A user can belong to several groups. This field defines the group id for which the group part of the permissions will apply.


=head2 tstamp

Last time this pagr was touched.

=head2 start

Time in seconds since the epoch when this page will be considered published.

=head2 stop

Time in seconds since the epoch till this page will be considered published.

=head2 published

0=not published,1=waiting,2=published


=head2 deleted

If set to "1" this page will not be accessible any more trough the system.

=head2 changed_by

User id of the user that touched this page for the last time.

=head1 METHODS

=head2 add

Inserts a new page row in C<my_pages> and adds basic properties 
(row in my_content with L<MYDLjE::M::Content/data_type> page)for the new page.

Returns an instance of L<MYDLjE::M::Page> - the newly created page.

In case of database error croaks with C<ERROR adding page(rolling back):[$@]>.

Parameters:

    #All columns can be passed as  key-value pairs like MYDLjE::M::select.

Example:

  require MYDLjE::M::Page;
  my $new_user = MYDLjE::M::Page->add(
  ...
  );

=head1 SEE ALSO

L<MYDLjE::M::Content>, L<MYDLjE::M::User>, L<MYDLjE::M>

=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров 

This code is licenced under LGPLv3.


