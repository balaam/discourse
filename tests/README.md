# Tests

To run all tests run `./run_tests.lua`.

## Filter

If you only want to run a few tests there's a filter.

`./run_tests.lua --filter "Speaker with no text gives error."

The filter matches tests names that begin with the filter string.

## Writing Tests

Open `run_tests.lua` in an editor and you'll see it's one long table called `tests`. Each entry in the `tests` table is a test.