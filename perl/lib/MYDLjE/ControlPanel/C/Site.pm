package MYDLjE::ControlPanel::C::Site;
use MYDLjE::Base 'MYDLjE::ControlPanel::C';

#Raw SQL for getting domains that belong to the current user
# OR the user belongs to a grup that has "read" and "write" permisttions
my $permissions_sql_AND =
    "( (user_id = ? AND permissions LIKE '_rw%')"
  . " OR (group_id IN (SELECT gid FROM my_users_groups WHERE uid= ?) "
  . " AND permissions LIKE '____rw%') )";

#TODO: make this SQL common for ALL tables with the mentioned columns,
#thus achieving commonly used permission rules everywhere.
my $domains_SQL =
  "SELECT * FROM my_domains WHERE $permissions_sql_AND ORDER BY domain";

sub domains {
  my $c   = shift;
  my $uid = $c->msession->user->id;

  #save some selects
  if ($c->msession('domains')) {
    $c->stash(domains => $c->msession('domains'));
  }
  else {
    $c->stash(domains => [$c->dbix->query($domains_SQL, $uid, $uid)->hashes]);
    $c->msession(domains => $c->stash('domains'));
  }
  return;
}

sub edit_domain {
  my $c = shift;
  require MYDLjE::M::Domain;
  my $id     = $c->stash('id');
  my $domain = MYDLjE::M::Domain->new;
  my $user   = $c->msession->user;

  if (defined $id) {
    $domain->select(
      id   => $id,
      -and => [\[$permissions_sql_AND, $user->id, $user->id]]
    );
  }
  if ($c->req->method eq 'GET') {
    $c->stash(form => $domain->data);
    return;
  }

  #handle POST
  my $v = $c->create_validator;
  $v->field('domain')->required(1)
    ->regexp($domain->FIELDS_VALIDATION->{domain}{regexp})
    ->message('Please enter valid domain name!');
  $v->field('name')->required(1)->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for human readable name!');
  $v->field('description')->required(1)
    ->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message('Please enter valid value for description!');
  $v->field('permissions')->required(1)
    ->regexp($domain->FIELDS_VALIDATION->{permissions}{regexp})
    ->message('Please enter valid value for permissions like "drwxrwxr--"!');

  my $all_ok = $c->validate($v);
  $c->stash(form => {%{$c->req->body_params->to_hash}, %{$v->values}});

  #$c->app->log->debug($c->dumper($c->stash));
  return unless $all_ok;
  $c->msession(domains => undef);

  my %ugids = ();

  #add user_id and group_id only if the domain is not the default or is new
  unless (defined $domain->id) {
    %ugids = (user_id => $user->id, group_id => $user->group_id);
  }

  #now we are ready to save
  $c->stash(id => $domain->save(%{$v->values}, %ugids));
  if (defined $c->stash('form')->{save_and_close}) {
    $c->redirect_to('/site/domains');
  }

  #$c->render();
  return;
}

sub pages {

}

sub edit_page {
  my $c = shift;

  require MYDLjE::M::Page;
  my $id      = $c->stash('id');
  my $page    = MYDLjE::M::Page->new;
  my $content = MYDLjE::M::Content->new;
  my $user    = $c->msession->user;

  $c->domains();    #fill in "domains" stash variable
  $c->stash(
    page_types => $page->FIELDS_VALIDATION->{page_type}{constraints}[0]{in});

  $c->stash(page_pid_options => $c->_set_page_pid_options($user));
  if ($id) {
    $page->select(
      id   => $id,
      -and => [\[$permissions_sql_AND, $user->id, $user->id]]
    );
    $content->select(
      page_id => $id,
      -and    => [\[$permissions_sql_AND, $user->id, $user->id]]
    );
    $c->stash(
      form => {
        (map { 'content.' . $_ => $content->$_() } @{$content->COLUMNS}),
        (map { 'page.' . $_ => $page->$_() } @{$page->COLUMNS})
      }
    );
  }
  if ($c->req->method eq 'POST') {
    $c->_save_page($page, $content);
  }

#$c->render();
  return;

}

sub _save_page {
  my ($c, $page, $content) = @_;
  my $req = $c->req;

  #validate
  my $v = $c->create_validator;
  $c->stash(form => $c->req->params->to_hash);
  my $form = $c->stash('form');
  $v->field('content.title')->required(1)
    ->inflate(\&MYDLjE::M::no_markup_inflate)
    ->message($c->l('The field [_1] is required!', $c->l('title')));
  $v->field('content.language')->in($c->app->config('languages'))->message(
    $c->l(
      'Please use one of the availabe languages or first add a new language!')
  );

  unless ($form->{'page.alias'}) {
    $form->{'page.alias'} =
      MYDLjE::Unidecode::unidecode($req->param('content.title'));
  }
  $v->field('page.alias')->regexp($page->FIELDS_VALIDATION->{alias}{regexp})
    ->message('Please enter valid page alias!');
  $v->field('page.domain_id')->in($c->stash('domains'))
    ->message(
    'Please use one of the availabe domains or first add a new domain!');

  # if domain_id is switched remove current pid
  if ($form->{'page.domain_id'} ne $page->domain_id) {
    $form->{'page.pid'} = 0;
  }
  $v->field('page.page_type')->in($c->stash('page_types'));
  $v->field('page.pid')->regexp($page->FIELDS_VALIDATION->{pid}{regexp});
  $v->field('page.description')->inflate(\&MYDLjE::M::no_markup_inflate);
  $v->field([qw(page.published page.hidden page.cache)])
    ->each(sub { shift->regexp($page->FIELDS_VALIDATION->{cache}{regexp}) });
  $v->field('page.expiry')->regexp();
  $c->app->log->debug($c->dumper($form));


  my $all_ok = $c->validate($v, $form);

  #replace form entries
  $c->stash(form => {%{$c->stash('form')}, %{$v->values}});

  #save
  #after save

  return;
}

#prepares an hierarshical looking list for page.pid select_field
sub _set_page_pid_options {
  my ($c, $user) = @_;
  my $page_pid_options = [{label => '/', value => 0}];
  $c->_traverse_children($user, 0, $page_pid_options, 0);
  return $page_pid_options;

}

sub _traverse_children {
  my ($c, $user, $pid, $page_pid_options, $depth) = @_;
  my $id = $c->stash('id') || 0;

  #Be reasonable and prevent deadly recursion
  $depth++;
  return if $depth > 10;
  my $domain_id = $c->req->param('page.domain_id') || 0;
  my $pages = $c->dbix->query(
    'SELECT id as value, alias as label, page_type, pid FROM my_pages'
      . ' WHERE pid=? AND domain_id=? AND pid !=? AND id>0' . ' AND '
      . $permissions_sql_AND,
    $pid, $domain_id, $id, $user->id, $user->id)->hashes;
  if (@$pages) {
    foreach my $page (@$pages) {
      if ($page->{value} == $id) {
        $page->{disabled} = 1;
      }
      $page->{label} = '-' x $depth . $page->{label};
      if ($page->{page_type} eq 'root') {

        #there can be only one root in a site
        $page_pid_options->[0]{disabled} = 1;
      }
      push @$page_pid_options, $page;
      $c->_traverse_children($user, $page->{value}, $page_pid_options, $depth,
        $id);
    }
  }
  return;
}

sub settings {
  my $c = shift;

#$c->render();
  return;
}


1;

