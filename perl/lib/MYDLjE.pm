package MYDLjE;
use MYDLjE::Base 'Mojolicious';
use MYDLjE::Config;

has controller_class => 'MYDLjE::C';
has env              => sub {
  if   ($_[1] && exists $ENV{$_[1]}) { $ENV{$_[1]} }
  else                               { \%ENV }
};
our $DEBUG = ((!$ENV{MOJO_MODE} || $ENV{MOJO_MODE} =~ /^dev/) ? 1 : 0);

my $CONFIG;

sub startup {
  my $app = shift;
  $CONFIG = MYDLjE::Config->singleton(log => $app->log);

  #Load Plugins
  $app->load_plugins();

  # Routes
  $app->load_routes();

  return;
}

sub config {
  my $app = shift;
  $CONFIG->stash(@_);
}

#load plugins from config file
sub load_plugins {
  my ($app) = @_;
  my $plugins = $app->config('plugins') || {};
  foreach my $plugin (keys %$plugins) {
    if ($plugins->{$plugin} && ref($plugins->{$plugin}) eq 'HASH') {
      $app->plugin($plugin => $plugins->{$plugin});
    }
    elsif ($plugins->{$plugin} && $plugins->{$plugin} =~ /^(1|y|true|on)/ix) {
      $app->plugin($plugin);
    }
  }
  return;
}

#load routes, described in config
sub load_routes {
  my ($app) = @_;
  my $r = $app->routes;
  my $routes = $app->config('routes') || {};
  foreach my $route (
    sort { $routes->{$a}{order} <=> $routes->{$b}{order} }
    keys %$routes
    )
  {

    my $way = $r->route($route);

    #TODO: support other routes descriptions beside 'via'
    if ($routes->{$route}{via}) {
      $way->via(@{$routes->{$route}{via}});
    }
    $way->to(%{$routes->{$route}{to}});
  }
  return;
}

#stolen from List::MoreUtils
sub _uniq (@) {
  my %seen = ();
  grep { not $seen{$_}++ } @_;
}


1;

__END__

=head1 NAME

MYDLjE - The Application class

=head1 DESCRIPTION

This class extends the L<Mojolicious> application class. It is the base 
class that L<MYDLjE::ControlPanel> and L<MYDLjE::Site> extend.
As the child application classes L<MYDLjE::ControlPanel> and L<MYDLjE::Site> have 
corresponding starter scripts L<cpanel> and L<site> 
this application class has its own L<mydlje> application starter. 
However this class implements only common functionality which is
shared by the L<cpanel> and L<site> applications.

You can make your own applications which inherit L<MYDLjE> or 
L<MYDLjE::ControlPanel> and L<MYDLjE::Site> depending on your needs.
And of course you can inherit directly from L<Mojolicious> and use only 
the bundled files and other perl modules for you own applications


=head1 ATTRIBUTES

L<MYDLjE> inherits all attributes from L<Mojolicious> and implements/overrides the following ones.

=head2 controller_class 

'MYDLjE::C'. See also L<MYDLjE::C>.

=head1 METHODS

L<MYDLjE> inherits all methods from L<Mojolicious> and implements the following new ones.

=head2 config

  my $all_config = $app->config;
  my $something = $app->config('something');

Getter for config values found in YAML config files.  On first and every subsequent 
call it returns the value of the specified key as parameter. If no key is 
specified returns the whole configuration hash-reference.
The config files are simply YAML. YAML seems cleaner to me. Note that 
MYDLjE is distributed with L<YAML::Any> and L<YAML::Tiny>. If on the 
system there are no oters YAML implementations installed L<YAML::Tiny> 
is used. Otherwise the implementation specifyed in L<YAML::Any/ORDER>
order of preference is used.


=head2 startup

This method initializes the application. It is called in 
L<MYDLjE::ControlPanel/startup> and L<MYDLjE::Site/startup>, then specific 
for these applications startups are done. 

We load the following plugins using L<load_plugins>
so they are available for use in  L<mydlje>, L<cpanel> and L<site>.

  charset
  validator
  pod_renderer
  ...others to be listed

Application charset is set to 'UTF-8'.

The following routes are pre-defined here:

  route                       name
  
  /perldoc                    perldoc              
  /:action                    action               
  /:action/:id                actionid             
  /:controller/:action/:id    controlleractionid   

The other routes are read from the configuration files. 
You can see all defined routes for the corresponding 
application on the commandline by executing it with the route command.

  Example:
  krasi@krasi-laptop:~/opt/public_dev/MYDLjE$ ./cpanel routes

=head2 load_plugins

Loads all plugins as described in YAML configuration files. Each plugin is 
treated as key=>value pair. The key is the plugin name and must be a string. 
The value can be either a scalar (interpreted as true/false) or a 
hash-reference. When the value is hash-reference it is passed as second argument 
to $app-E<gt>L<plugin|Mojolicious/plugin>.

Example plugins configuration:

  #in MYDLjE/conf/mydlje.development.yaml
  plugins:
    charset: 
        charset: 'UTF-8'
    #enabled
    validator: 1
    #disabled
    pod_renderer: 0


=head1 SEE ALSO

L<MYDLjE::Guides>, L<MYDLjE::ControlPanel>, 
L<MYDLjE::Site>, L<MYDLjE::Config>,L<Hash::Merge>, L<YAML::Tiny>


