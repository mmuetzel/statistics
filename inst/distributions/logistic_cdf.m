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
## @deftypefn {} {} logistic_cdf (@var{x})
## @deftypefnx {} {} logistic_cdf (@var{x}, @var{mu}, @var{scale})
## For each element of @var{x}, compute the cumulative distribution function
## (CDF) at @var{x} of the logistic distribution with mean @var{mu} and scale
## parameter @var{scale}.
## @end deftypefn

## Author: KH <Kurt.Hornik@wu-wien.ac.at>
## Description: CDF of the logistic distribution

function cdf = logistic_cdf (x, mu = 0, scale = 1)

  if (nargin < 1 || nargin > 3)
    print_usage ();
  endif

  if (iscomplex (x))
    error ("logistic_cdf: X must not be complex");
  endif

  cdf = 1 ./ (1 + exp (- (x - mu) / scale));

endfunction


%!shared x,y
%! x = [-Inf -log(3) 0 log(3) Inf];
%! y = [0, 1/4, 1/2, 3/4, 1];
%!assert (logistic_cdf ([x, NaN]), [y, NaN], eps)

## Test class of input preserved
%!assert (logistic_cdf (single ([x, NaN])), single ([y, NaN]), eps ("single"))

## Test input validation
%!error logistic_cdf ()
%!error logistic_cdf (1,2,3,4)
%!error logistic_cdf (i)
