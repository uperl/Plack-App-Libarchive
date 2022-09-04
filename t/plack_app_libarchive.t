use Test2::V0 -no_srand => 1;
use experimental qw( postderef );
use Plack::App::Libarchive;
use Test2::Tools::HTTP;
use Test2::Tools::DOM;
use HTTP::Request::Common;
use Plack::Builder ();
use Mojo::DOM58;
use URI;

psgi_app_add(Plack::App::Libarchive->new(archive => 'corpus/foo.tar')->to_app);

subtest 'index' => sub {

  http_request (
    GET('/'),
    http_response {
      http_code 200;
      http_content_type 'text/html';
      http_content dom {
        find 'title' => [
          dom { content 'foo.tar' }
        ];
        find 'ul li a' => [
          dom { attr href => 'foo.html' },
          dom { attr href => 'foo.txt' },
        ]
      };
    },
  );

  note http_tx->res->as_string;

};

subtest 'foo.txt' => sub {

  http_request (
    GET('/foo.txt'),
    http_response {
      http_code 200;
      http_content_type 'text/plain';
      http_content "Hello World\n";
    }
  );

  note http_tx->res->as_string;

};

subtest '404' => sub {

  http_request (
    GET('/frooble-bits.txt'),
    http_response {
      http_code 404;
      http_content_type 'text/plain';
      http_content 'Not Found';
    },
  );

  note http_tx->res->as_string;

};

subtest 'mount elsewhere' => sub {


  psgi_app_add( 'http://mount-point.test' => do {
    my $builder = Plack::Builder->new;
    $builder->mount('/frooble' => Plack::App::Libarchive->new(archive => 'corpus/foo.tar')->to_app);
    $builder->to_app;
  });

  my $url = URI->new('http://mount-point.test/frooble');

  http_request (
    GET($url),
    http_response {
      http_code 301;
      http_header 'location', '/frooble/';
    }
  );

  $url->path(http_tx->res->header('location'));

  http_request (
    GET($url),
    http_response {
      http_code 200;
      http_content_type 'text/html';
      http_content dom {
        find 'title' => [
          dom { content 'foo.tar' }
        ];
        find 'ul li a' => [
          dom { attr href => 'foo.html' },
          dom { attr href => 'foo.txt' },
        ]
      }
    }
  );

  foreach my $href (map { $_->attr('href') } Mojo::DOM58->new(http_tx->res->decoded_content)->find('ul li a')->to_array->@*)
  {
    my $url = URI->new_abs( $href, $url );

    http_request (
      GET($url),
      http_response {
        http_code 200;
      }
    );
  }

};

done_testing;
