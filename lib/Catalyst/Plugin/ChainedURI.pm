package Catalyst::Plugin::ChainedURI;
# ABSTRACT: Simple way to get an URL to an action from chained catalyst controller
use strict;
use warnings;

sub chained_uri {
	my ( $c, $controller, $action_for, @ca ) = @_;
	my $control = $c->controller($controller);

	die "Catalyst::Plugin::ChainedURI can't get controller ".$controller if !$control;
	
	my $action = $control->action_for($action_for);

	die "Catalyst::Plugin::ChainedURI can't get action ".$action_for." on controller ".$controller if !$action;
	
	die "Catalyst::Plugin::ChainedURI needs Chained action as target (given: ".$controller."->".$action_for.")" if !$action->attributes->{Chained};
	die "Catalyst::Plugin::ChainedURI needs the end of the chain as target (given: ".$controller."->".$action_for.")" if $action->attributes->{CaptureArgs};
	
	if ($c->log->is_debug) {
		$c->log->debug('ChainedURI '.$controller.'->'.$action_for.' '.join(',',@ca));
	}

	my @captures;
	my $curr = $action;
	my $i = 0;
	while ($curr) {
		$i++;
		if (my $cap = $curr->attributes->{CaptureArgs}) {
			my $cc = $cap->[0];
			for (@{$curr->attributes->{StashArg}}) {
				if ($_) {
					$cc--;
					die "Catalyst::Plugin::ChainedURI: too many StashArg attributes on given action '".$action."'" if $cc < 0;
					push @captures, $c->stash->{$_};
				}
			}
			die "Catalyst::Plugin::ChainedURI: the given action '".$action."' needs more captures" if @ca < $cc; # not enough captures
			if ($cc) {
				my @splice = splice(@ca, 0, $cc);
				unshift(@captures, @splice);
			}
		}
		my $parent_path = $curr->attributes->{Chained}->[0];
		$curr = $parent_path eq '/' ? undef : $c->dispatcher->get_action_by_path($parent_path);
		$curr = undef if $i > 10;
	}
	
	@captures = reverse @captures;

	return $c->uri_for_action($action,\@captures,@ca);
}

=head1 SYNOPSIS

  # In the Root controller, for example:

  sub base :Chained('/') :PathPart('') :CaptureArgs(1) :StashArg('language') {
    my ( $c, $language ) = @_;
    ...
    $c->stash->{language} = $language;
    ...
  }
  
  sub othercapture :Chained('base') :PathPart('') :CaptureArgs(1) { ... }
  sub final :Chained('othercapture') :PathPart('') :Args(1) { ... }
  
  # Somewhere

  my $uri = $c->chained_uri('Root','final',$othercapture_capturearg,$final_arg);

  # Usage hints
  
  $c->stash->{u} = sub { $c->chained_uri(@_) }; # for getting [% u(...) %]

=head1 DESCRIPTION

B<TODO>

=head1 SUPPORT

IRC

  Join #catalyst on irc.perl.org and ask for Getty.

Repository

  http://github.com/Getty/p5-catalyst-plugin-chaineduri
  Pull request and additional contributors are welcome
 
Issue Tracker

  http://github.com/Getty/p5-catalyst-plugin-chaineduri/issues

=cut

1;
