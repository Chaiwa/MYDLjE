package MYDLjE::ControlPanel;
use MYDLjE::Base 'MYDLjE';


has controller_class => 'MYDLjE::ControlPanel::C';

#TODO:: think of better config implementation - may be subclass Mojolicious::Plugin::Config
my $CONFIG;

sub startup {
  my $app = shift;
  $CONFIG = MYDLjE::Config->singleton(log => $app->log);
  $app->secret($app->config('secret'));
  $app->sessions->cookie_name($app->config('session_cookie_name'));

  #Load Plugins
  $app->load_plugins();

  # Routes
  my $r = $app->routes;
  $r->namespace($app->controller_class);
  $r->route('/hi')->to(action => 'hi', controller => 'home', id => 1);
  return unless $app->config('installed');
  my $routes_config = $app->config('routes');
  $r->route('/loginscreen')
  ->to($routes_config->{'/loginscreen'}{to});
  my $bridge_to = $routes_config->{'/isauthenticated'}{to};
  $r->route('/isauthenticated')->to($bridge_to);
  my $login_required_routes = $r->bridge('/')->to($bridge_to);

  #Login Required Routes (bridged trough login)
  $app->load_routes($login_required_routes,
    $app->config('login_required_routes'));

  #$app->load_routes();

  $app->renderer->root($app->home . '/' . $app->config('templates_root'))
    if $app->config('templates_root');

  #Additional Content-TypeS (formats)
  $app->add_types();

  #Hooks
  $app->hook(before_dispatch => \&MYDLjE::before_dispatch);
  $app->hook(after_dispatch  => \&MYDLjE::after_dispatch);

  return;
}

sub config {
  shift;
  return $CONFIG->stash(@_);
}

1;

__END__

=head1 NAME

MYDLjE::ControlPanel - The L<cpanel> Application class

=head1 DESCRIPTION


=head1 ATTRIBUTES

L<MYDLjE::ControlPanel> inherits most attributes from L<MYDLjE> and implements/overrides the following ones.

=head2 controller_class 

L<MYDLjE::ControlPanel::C>

