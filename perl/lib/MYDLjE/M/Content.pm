package MYDLjE::M::Content;
use MYDLjE::Base 'MYDLjE::M';
require MYDLjE::Unidecode;
require Time::HiRes;
require I18N::LangTags::List;

our $VERSION = '0.5';

has TABLE => 'my_content';

has COLUMNS => sub {
  [ qw(
      id alias pid page_id user_id sorting data_type data_format
      time_created tstamp title description keywords tags
      body language group_id permissions featured bad start stop
      )
  ];
};

has WHERE => sub { {deleted => 0} };

sub _tags_inflate {
  my $filed = shift;
  my $value = $filed->value || '';

  #$value =~ s/[^\p{IsAlnum}-\,\s]//gxi;
  $value = lc($value);
  my @words = split /[^\p{IsAlnum}-]+/xi, $value;
  $value = join ", ", @words;
  return $value;
}

sub _language_inflate {
  my $filed = shift;
  my $value = $filed->value || '';
  return $value unless ($value);
  $value = '' unless (I18N::LangTags::List::name($value));

  return $value;
}

has FIELDS_VALIDATION => sub {
  my $self = shift;
  return {
    $self->FIELD_DEF('id'),
    $self->FIELD_DEF('pid'),
    $self->FIELD_DEF('permissions'),
    $self->FIELD_DEF('user_id'),
    $self->FIELD_DEF('group_id'),
    $self->FIELD_DEF('sorting'),
    $self->FIELD_DEF('alias'),
    $self->FIELD_DEF('title'),
    tags     => {required => 0, inflate => \&_tags_inflate},
    keywords => {required => 0, inflate => \&_tags_inflate},
    $self->FIELD_DEF('description'),
    data_type => {
      required    => 1,
      constraints => [
        { regexp =>
            qr/^(page|question|answer|book|note|article|chapter|content)$/x
        },
      ]
    },
    data_format => {
      required    => 1,
      constraints => [{regexp => qr/(textile|text|html|markdown|template)/x},]
    },
    language => {

      #required    => 1,
      inflate     => \&_language_inflate,
      constraints => [{regexp => qr/^[a-z]{0,2}$/x},]
      }

  };
};

sub new { my $self = shift->SUPER::new(@_); $self->data_type; return $self; }

#Make some attributes which are appropriate to any data_type of content

sub alias {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{alias} = $self->validate_field(alias => $value);
    return $self;
  }

  unless ($self->{data}{alias}) {
    $self->{data}{alias} = lc(
      $self->title
      ? MYDLjE::Unidecode::unidecode($self->title)
      : Mojo::Util::md5_sum(Time::HiRes::time())
    );
    $self->{data}{alias} =~ s/\W+$//x;
    $self->{data}{alias} =~ s/^\W+//x;
  }
  return $self->{data}{alias};
}

sub data_type {
  my ($self, $value) = @_;
  if ($value) {
    $self->{data}{data_type} = $self->validate_field(data_type => $value);

    return $self;
  }
  unless ($self->{data}{data_type}) {
    my $type = lc(ref($self));
    $type =~ /(\w+)$/x and $self->{data}{data_type} = $1;
  }
  return $self->{data}{data_type};
}

sub tstamp {
  my ($self) = @_;
  return $self->{data}{tstamp} ||= time;    #setting getting
}

sub id {
  my ($self, $value) = @_;
  if (defined $value) {                     #setting
    $self->{data}{id} = $self->validate_field(id => $value);
    return $self;
  }
  return $self->{data}{id};                 #getting
}

sub user_id {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{user_id} = $self->validate_field(user_id => $value);
    return $self;
  }
  return $self->{data}{user_id};            #getting
}

sub group_id {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{group_id} = $self->validate_field(group_id => $value);
    return $self;
  }
  return $self->{data}{group_id};           #getting
}

sub pid {
  my ($self, $value) = @_;
  if (defined $value) {                     #setting
    $self->{data}{pid} = $self->validate_field(pid => $value);
    return $self;
  }
  return $self->{data}{pid};                #getting
}

sub title {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{title} = $self->validate_field(title => $value);
    return $self;
  }
  return $self->{data}{title};              #getting
}

sub tags {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{tags} = $self->validate_field(tags => $value);
    return $self;
  }
  return $self->{data}{tags};               #getting
}

sub keywords {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{keywords} = $self->validate_field(keywords => $value);
    return $self;
  }
  return $self->{data}{keywords};           #getting }
}

sub featured {
  my ($self, $value) = @_;
  if ($value) {                             #setting
    $self->{data}{featured} = 1;
    return $self;
  }
  return $self->{data}{featured} if defined $self->{data}{featured};  #getting
  return $self->{data}{featured} = 0;                                 #default
}

sub sorting {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{sorting} = $self->validate_field(sorting => $value);
    return $self;
  }
  return $self->{data}{sorting};                                      #getting
}

sub data_format {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{data_format} = $self->validate_field(data_format => $value);
    return $self;
  }
  return $self->{data}{data_format};                                  #getting
}

sub time_created {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    if   ($value =~ /(\d{10,})/x) { $self->{data}{time_created} = $1 }
    else                          { $self->{data}{time_created} = time; }
    return $self;
  }
  return $self->{data}{time_created} ||= time;                        #getting
}

sub body {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{body} = $self->validate_field(body => $value);
    return $self;
  }
  return $self->{data}{body};                                         #getting
}


sub language {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{language} = $self->validate_field(language => $value);
    return $self;
  }
  return $self->{data}{language} ||= '';                              #getting
}


sub bad {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    $self->{data}{bad}++;
    return $self;
  }
  return $self->{data}{bad} if defined $self->{data}{bad};            #getting
  return $self->{data}{bad} = 0;                                      #default
}

sub start {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    if   ($value =~ /(\d{10,})/x) { $self->{data}{start} = $1 }
    else                          { $self->{data}{start} = 0; }
    return $self;
  }
  return $self->{data}{start} ||= 0;                                  #getting
}

sub stop {
  my ($self, $value) = @_;
  if ($value) {                                                       #setting
    if   ($value =~ /(\d{10,})/x) { $self->{data}{stop} = $1 }
    else                          { $self->{data}{stop} = 0; }
    return $self;
  }
  return $self->{data}{stop} ||= 0;                                   #getting
}

1;

__END__

=encoding utf8

=head1 NAME

MYDLjE::M::Content - Base class for all semantic content data_types

=head1 DESCRIPTION

This is the MYDLjE Perl API to the database table C<my_content>. In MYDLjE all the content is stored in a database table - C<my_content>. There are several semantic types of content. This semantic type is determined by the value stored in column L<data_type>.

This is the base class which all content related classes should inherit. Basically all they need to do is to define their own  C<WHERE> method. See L<MYDLjE::M/WHERE>.

=head1 ATTRIBUTES

MYDLjE::M::Content inherits all attributes from MYDLjE::M and defines the following ones. 

=head2 FIELDS_VALIDATION

Constraints for validating data fields when populating them. See L<MYDLjE::M/FIELDS_VALIDATION>.

=head1 DATA ATTRIBUTES

The uniqueness of a L<MYDLjE::M::Content> instance is defined by its L</id> data attribute. 
A data attribute represents the value stored in a column of a row in C<my_content> table. 
In Perl sense these are small methods (getters and setters). 
When you instantiate an object either using the inherited L<MYDLjE::M/select> method or via C<new()> some of these attributes are populated. 
Note that when you instantiate via C<new()> not all the attributes are populated (but see the specific attributes for details). 
The same happens when you instantiate via C<select> but no data is found in the table. 

All data attributes usually return C<$self> when setting and the current value when getting.


=head2 alias

Parameter:

    #STRING - the string from which the alias will be prepared.
                                      
Returns:

    #$self - when setting
    $page->alias('My Page Title. YEAH!'); #$self
    #Unidecoded, lowercased and trimmed of \W characters $value - when getting
    $page->alias;# my-page-title--yeah

Always tries to construct an alias out of the L</title> data attribute if there is not an alias already. So to get this automatic behavior set title first. 
When no title is set creates an md5sum (C<Mojo::Util::md5_sum(Time::HiRes::time())>).

    $page->title('Христос възкръсна!')->alias; # 'xristos-vazkrasna'

The constructed alias should be a C<UNIQUE> value for the current L</data_type>. A database exception occurs if not.

    $page->alias('Христос възкръсна!');
    $page->save(); #OK
    #later...
    $book->alias('Христос възкръсна!');
    $book->save(); #OK
    
    $note->alias('My Note');
    $save->save(); #Good...
    #later...
    $another_note->alias('My Note');#10,9,8,7..
    #...3,2,1
    $another_note->save(); #CABOOM!


=head2 bad

Represents a boolean value(0/1). When an argument is passed just increments with 1 the current value. 
Used to report a content element as inappropriate/bad.

    #$self->bad(1)->bad('whatever')->bad;# 2
    
    #..in another next request or galaxy;
    $self->bad;#2
    $self->bad(1);
    $self->bad;#3


=head2 body

Represents the main content (body) of the content element. 
The value will be interpreted depending on the L</data_format> attribute when displayed in a browser.


=head2 data_format

At the time of writing the following data formats are accepted/recognized:

    qr/(textile|text|html|markdown,template)/x

=head2 data_type

Auto-generated based on the reference of the current object. Auto-populated during instantiation. Can be overwritten.

    # I have a bright idea about a new data_type but I do not want (yet) to 
    # define another MYDLjE::M::Content::MyNewBrightIdea class
    my $custom_semantic_type = MYDLjE::M::Content->new(user_id=>2);
    delete $custom_semantic_type->FIELDS_VALIDATION->{data_type}{constraints};
    $custom_semantic_type->data_type('foo_bar');
    $custom_semantic_type->title('My note');
    $custom_semantic_type->body('body of My note');
    $custom_semantic_type->save();#OK
    
    #time passes...    
    #Retrieve it
    my $my_custom = MYDLjE::M::Content->new;
    delete $my_custom->FIELDS_VALIDATION->{data_type}{constraints};
    $my_custom->data_type('foo_bar');
    $my_custom->alias('my-note');
    $my_custom->select()->body;# 'body of My note'
    
 
=head2 featured

Boolean (0/1). Will be used in MYDLjE::M::Site to list/display featured items only.

=head2 group_id

Represents the group_id to which this content belongs. By default this is the group_id of the owner/creator of this content (user_id).

=head2 id

Auto-populated upon first L</save> and upon select. Do not set it unless you are sure!

=head2 invisible

Boolean (0/1).


=head2 keywords

Works exactly the same way as L</tags>, but populates the keywords column.

=head2 language

Getter/seter for the C<language> column. Accepts only two letter language abbreviations. Uses L<I18N::LangTags::List> to validate the argument if it is a valid language tag. Defaults to C<'en'>.


=head2 pid

Accepts an integer. Represents the parent record C<ID> of the current record.
For example an answer has a parent question. Several answers may have the same C<pid>.
An article can have a C<pid> pointing to a page C<ID> with title "Articles"... etc.

=head2 protected

Boolean (0/1). TODO...

=head2 sorting

Accepts an integer. Eventually used to C<ORDER BY sorting>. 

=head2 tags

Accepts a comma separated string of words. A valid word is one or more alphanumeric characters. in this case '-' is also treated as alphanumeric character. Tries to do it's best in guessing the separator. Does  L<lc> on the string.

    $self->tags('perl,| Content-Management,   javaScript||jAvA');
    $self->tags; #'perl, content-management, javascript, java'

=head2 time_created

Getter/setter for the time when this content was created. Accepts seconds since the Unix epoch. Defaults to L<time>.

=head2 title

Accepts string. 
Cleaned up upon validation using the following regexp: C<s/[^\p{IsAlnum}\,\s\-\!\.\?\(\);]//gx>.
Any character after the 255th is silently removed.

=head2 tstamp

Getter/setter for the tstamp column. Accepts seconds since the Unix epoch. Defaults to L<time>.

=head2 user_id

Getter/setter for the user id. Usually the id of the user that created the content. In the table this field has a foreign key constraint an references C<my_users.id>.

=head1 METHODS

This class inherits all methods from L<MYDLjE::M> and overwrites the following ones.

=head2 new

Calls L<data_type> to have it defined upon L<MYDLjE::M/save>.

=head1 EXAMPLES

Not yet.. but there are plenty of them in C<perl/t/05_m.t>.

=head1 SEE ALSO

L<MYDLjE::M::Content::Answer>, L<MYDLjE::M::Content::Article>, L<MYDLjE::M::Content::Book>, L<MYDLjE::M::Content::Chapter>, L<MYDLjE::M::Content::Note>, L<MYDLjE::M::Content::Page>, L<MYDLjE::M::Question>


=head1 AUTHOR AND COPYRIGHT

(c) 2011 Красимир Беров 

This code is licenced under LGPLv3.


