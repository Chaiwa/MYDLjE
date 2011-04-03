package MYDLjE::M::Session;
use MYDLjE::Base 'MYDLjE::M';
use Mojo::Util qw();
use MYDLjE::M::User;
require Time::HiRes;
has user => sub { MYDLjE::M::User->select(login_name => 'guest') };
has TABLE => 'my_sessions';

has COLUMNS => sub { [qw(id cid user_id tstamp sessiondata)] };

has FIELDS_VALIDATION => sub {
  return {
    id  => {required => 1, constraints => [{regexp => qr/^[a-f0-9]{32}$/x},]},
    cid => {required => 0, constraints => [{regexp => qr/^\d+$/x},]},
    user_id     => {required => 1, constraints => [{regexp => qr/^\d+$/x},]},
    sessiondata => {
      required => 1,
      inflate  => sub {
        my $self = shift;

        #warn Data::Dumper::Dumper($self->value);
        if (!ref($self->value)) {
          $self->value(_thaw_sessiondata($self->value));
        }

        #warn Data::Dumper::Dumper($self->value);
        return $self->value;
      },
      constraints => [
        { callback => sub {
            my $value = shift;

            #We inflated it but who knows
            return 1 if ($value and ref($value) eq 'HASH');
            return (0, 'Value is not a HASH reference');
            }
        },
      ]
    },
  };
};

sub new_id {
  my ($self, $new_id) = @_;
  if ($new_id) {
    Carp::confess('News session id does not look like an md5_sum!')
      unless $new_id =~ m|^[a-f0-9]{32}$|x;
    my $self->{new_id} = $new_id;
  }
  if (!$self->{new_id}) {
    my $time = Time::HiRes::time();
    $self->{new_id} = Mojo::Util::md5_sum(rand($time) . rand($time) . $time);
  }
  return $self->{new_id};
}

sub user_id {
  my ($self, $user_id) = @_;
  if ($user_id) {
    $self->{data}{user_id} = $self->validate_field(user_id => $user_id);

    #synchronize
    unless ($self->{data}{user_id} == $self->user->id) {
      $self->user(MYDLjE::M::User->select(id => $user_id));
      $self->{data}{user_id} = $self->user->id;
    }
    return $self->{data}{user_id};
  }
  $self->{data}{user_id} ||= $self->user->id;
  warn $self->{data}{user_id};

  #we always have a user id - "guest user id" by default
  return $self->{data}{user_id};
}

sub sessiondata {
  my ($self, $sessiondata) = @_;
  if ($sessiondata) {

    #not chainable
    $self->{data}{sessiondata} =
      $self->validate_field(sessiondata => $sessiondata);

  }
  return $self->{data}{sessiondata} ||= {};
}

sub _freeze_sessiondata {
  my $value = shift;
  local $Carp::CarpLevel = 2;
  Carp::confess('Value for sessiondata is not a HASH reference!')
    unless ref($value) eq 'HASH';
  return $value = MIME::Base64::encode_base64(Storable::nfreeze($value));
}

sub _thaw_sessiondata {
  my $value = shift;
  ref($value)
    && Carp::confess(
    'Value for thawing sessiondata must not be a reference!');
  return Storable::thaw(MIME::Base64::decode_base64($value));
}

sub tstamp { return $_[0]->{data}{tstamp} = time; }

sub save {
  my $self = shift;

  $self->sessiondata->{user_data} ||= $self->user->data;
  if (!$self->id) {    #a fresh new session
    $self->id($self->new_id());

    $self->dbix->insert(
      $self->TABLE,
      { id          => $self->id,
        tstamp      => time,
        user_id     => $self->user_id,
        sessiondata => _freeze_sessiondata($self->sessiondata)
      }
    );
    return $self->id;
  }
  else {
    $self->data->{tstamp} = $self->tstamp;
    $self->data(sessiondata => _freeze_sessiondata($self->sessiondata));
    $self->dbix->update($self->TABLE, $self->data, {id => $self->id});
  }
  $self->data(sessiondata => _thaw_sessiondata($self->sessiondata));
  return $self->id;
}

sub select {    ##no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ($self, $where) = MYDLjE::M::get_obj_args(@_);

  #instantiate if needed
  unless (ref $self) {
    $self = $self->new();
  }
  $where = {%{$self->WHERE}, %$where};

  #TODO: Implement restoring object from session state
  $self->data(
    $self->dbix->select($self->TABLE, $self->COLUMNS, $where)->hash);
  if ($self->sessiondata && !ref($self->sessiondata)) {
    $self->data(sessiondata => _thaw_sessiondata($self->sessiondata));
  }
  return $self;
}
1;

__END__

=head1 NAME

MYDLjE::M::Session - MYDLjE::M based Session storage for MYDLjE

=head1 SYNOPSIS

  # get session data from database or create a new session storage object
  my $session_storage = MYDLjE::M::Session->select(id=>$c->session('id'));
  
  #do we have an authenticated user?
  my $user = $session_storage->user;
  if ($user->login_name ne 'quest'){
      #Do something specific with the user
  }
=head1 DESCRIPTION

MYDLjE::M::Session is to store session data in the MYDLjE database.
It is just an implementation of the abstract class L<MYDLjE::M>.



