#!/usr/bin/env plackup
use Object::Pad ':experimental(:all)';

package casrv;
class casrv :does(Frame);

method startup {
  my $r = $self->routes;
  
  my $ca = $r->under('/ca/', sub ($self) {
	my $jsonstr = $self->req->content_body
  });

  my $ = $r->under('/leaf/', sub ($self) {
  
  });
  
  $auth->post('/newcert', sub ($self) {
    
  });
}:w
`
