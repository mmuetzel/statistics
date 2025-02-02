## Copyright (C) 2012 Rik Wehbring
## Copyright (C) 1995-2016 Kurt Hornik
##
## This program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {} logistic_inv (@var{x})
## @deftypefnx {} {} logistic_pdf (@var{x}, @var{mu}, @var{scale})
## For each element of @var{x}, compute the quantile (the inverse of the CDF)
## at @var{x} of the logistic distribution with mean @var{mu} and scale
## parameter @var{scale}.
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Description: Quantile function of the logistic distribution

function inv = logistic_inv (x, mu = 0, scale = 1)

  if (nargin < 1 || nargin > 3)
    print_usage ();
  endif

  if (iscomplex (x))
    error ("logistic_inv: X must not be complex");
  endif

  if (isa (x, "single"))
    inv = NaN (size (x), "single");
  else
    inv = NaN (size (x));
  endif

  k = (x == 0);
  inv(k) = -Inf;

  k = (x == 1);
  inv(k) = Inf;

  k = (x > 0) & (x < 1);
  inv(k) = mu + scale * log (x(k) ./ (1 - x(k)));

endfunction


%!shared x
%! x = [-1 0 0.5 1 2];
%!assert (logistic_inv (x), [NaN -Inf 0 Inf NaN])

%!test
%! p = [0.01:0.01:0.99];
%! assert (logistic_inv (p), log (p ./ (1-p)), 25*eps);

## Test class of input preserved
%!assert (logistic_inv ([x, NaN]), [NaN -Inf 0 Inf NaN NaN])
%!assert (logistic_inv (single ([x, NaN])), single ([NaN -Inf 0 Inf NaN NaN]))

## Test input validation
%!error logistic_inv ()
%!error logistic_inv (1,2,3,4)
%!error logistic_inv (i)
