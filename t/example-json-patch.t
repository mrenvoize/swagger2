use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_ONLINE=1' unless $ENV{TEST_ONLINE};

#
# https://github.com/OAI/OpenAPI-Specification/issues/57
# The swagger spec does not support oneOf, anyOf, ...
# so you cannot include JSON Schema specs such as
# http://json.schemastore.org/json-patch.json directly.
#
# This test is an example to implement parts of the spec
# in a different way.
#
# TODO: Make sure "path" is also part of the spec, using "discriminator":
# https://github.com/jhthorsen/swagger2/issues/72
#
# http://json.schemastore.org/json-patch.json#/definitions/operation/oneOf/0
#  => "patch"
#     Add, replace or test.
#
# http://json.schemastore.org/json-patch.json#/definitions/operation/oneOf/1
#  => "delete"
#     DELETE can take a HTTP body, so it can either delete
#     the whole object, or parts of the object.
#     http://tools.ietf.org/html/draft-ietf-httpbis-p2-semantics-19#section-6.7
#
# http://json.schemastore.org/json-patch.json#/definitions/operation/oneOf/2
#  => Not implemented
#

use Mojolicious::Lite;
eval { plugin Swagger2 => {url => 'data://main/def.json'} };
is $@, '', 'valid swagger spec';

if ($ENV{TEST_ONLINE} == 2) {
  local $Data::Dumper::Deepcopy  = 1;
  local $Data::Dumper::Indent    = 1;
  local $Data::Dumper::Pair      = ': ';
  local $Data::Dumper::Quotekeys = 1;
  local $Data::Dumper::Sortkeys  = 1;
  local $Data::Dumper::Terse     = 1;
  local $Data::Dumper::Useqq     = 1;
  diag Data::Dumper::Dumper(JSON::Validator->new->schema("data://main/def.json")->schema->data);
}

done_testing;

__DATA__
@@ def.json
{
  "swagger": "2.0",
  "info": { "version": "9.1", "title": "Test API for json-patch" },
  "paths": {
    "/some/object": {
      "delete": {
        "operationId": "deleteMe",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "description": "Remove the whole or parts of the object",
            "schema": {
              "type": "array",
              "items": {
                "$ref": "http://json.schemastore.org/json-patch.json#/definitions/operation/oneOf/1"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "this is required",
            "schema": { "type": "object" }
          }
        }
      },
      "patch": {
        "operationId": "patchMe",
        "parameters": [
          {
            "name": "data",
            "in": "body",
            "description": "Add, replace or test",
            "required": true,
            "schema": {
              "type": "array",
              "items": {
                "$ref": "http://json.schemastore.org/json-patch.json#/definitions/operation/oneOf/0"
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "this is required",
            "schema": { "type": "object" }
          }
        }
      }
    }
  }
}
