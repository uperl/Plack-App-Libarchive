use Test2::V0 -no_srand => 1;
use Plack::App::Libarchive;
use Test2::Tools::HTTP;
use HTTP::Request::Common;
use Mojo::DOM58;

Test2::Tools::HTTP::Tx->add_helper(
  'res.dom' => sub {
    my($res) = @_;
    Mojo::DOM58->new($res->decoded_content);
  },
);

psgi_app_add(Plack::App::Libarchive->new(archive => 'corpus/foo.tar')->to_app);

subtest 'index' => sub {

  http_request (
    GET('/'),
    http_response {
      http_code 200;
      http_content_type 'text/html';
      call dom => object {
        call [find => 'title'] => object {
          call first => object {
            call content => 'foo.tar';
          };
        };
        call [find => 'ul li a'] => object {
          call to_array => array {
            item object {
              call [attr => 'href'] => '/foo.html';
              call content => 'foo.html';
            };
            item object {
              call [attr => 'href'] => '/foo.txt';
              call content => 'foo.txt';
            };
            end;
          };
        };
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

done_testing;
