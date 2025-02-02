## Copyright (C) 2022 Nicholas R. Jankowski
## Copyright (C) 2012 Rik Wehbring
## Copyright (C) 1997-2016 Kurt Hornik
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
## @deftypefn  {} {} hygernd (@var{t}, @var{m}, @var{n})
## @deftypefnx {} {} hygernd (@var{t}, @var{m}, @var{n}, @var{r})
## @deftypefnx {} {} hygernd (@var{t}, @var{m}, @var{n}, @var{r}, @var{c}, @dots{})
## @deftypefnx {} {} hygernd (@var{t}, @var{m}, @var{n}, [@var{sz}])
## Return a matrix of random samples from the hypergeometric distribution
## with parameters @var{t}, @var{m}, and @var{n}.
##
## The parameters @var{t}, @var{m}, and @var{n} must be positive integers
## with @var{m} and @var{n} not greater than @var{t}.
##
## When called with a single size argument, return a square matrix with
## the dimension specified.  When called with more than one scalar argument the
## first two arguments are taken as the number of rows and columns and any
## further arguments specify additional matrix dimensions.  The size may also
## be specified with a vector of dimensions @var{sz}.
##
## If no size arguments are given then the result matrix is the common size of
## @var{t}, @var{m}, and @var{n}.
## @end deftypefn

function rnd = hygernd (t, m, n, varargin)

  if (nargin < 3)
    print_usage ();
  endif

  if (! isscalar (t) || ! isscalar (m) || ! isscalar (n))
    [retval, t, m, n] = common_size (t, m, n);
    if (retval > 0)
      error ("hygernd: T, M, and N must be of common size or scalars");
    endif
  endif

  if (iscomplex (t) || iscomplex (m) || iscomplex (n))
    error ("hygernd: T, M, and N must not be complex");
  endif

  if (nargin == 3)
    sz = size (t);
  elseif (nargin == 4)
    if (isscalar (varargin{1}) && varargin{1} >= 0)
      sz = [varargin{1}, varargin{1}];
    elseif (isrow (varargin{1}) && all (varargin{1} >= 0))
      sz = varargin{1};
    else
      error ("hygernd: dimension vector must be row vector of non-negative integers");
    endif
  elseif (nargin > 4)
    if (any (cellfun (@(x) (! isscalar (x) || x < 0), varargin)))
      error ("hygernd: dimensions must be non-negative integers");
    endif
    sz = [varargin{:}];
  endif

  if (! isscalar (t) && ! isequal (size (t), sz))
    error ("hygernd: T, M, and N must be scalar or of size SZ");
  endif

  if (isa (t, "single") || isa (m, "single") || isa (n, "single"))
    cls = "single";
  else
    cls = "double";
  endif

  ok = ((t >= 0) & (m >= 0) & (n > 0) & (m <= t) & (n <= t) &
        (t == fix (t)) & (m == fix (m)) & (n == fix (n)));

  if (isscalar (t))
    if (ok)
      v = 0:n;
      p = hygepdf (v, t, m, n);
      rnd = v(lookup (cumsum (p(1:end-1)) / sum (p), rand (sz)) + 1);
      rnd = reshape (rnd, sz);
      if (strcmp (cls, "single"))
        rnd = single (rnd);
      endif
    else
      rnd = NaN (sz, cls);
    endif
  else
    rnd = NaN (sz, cls);
    n = n(ok);
    num_n = numel (n);
    v = 0 : max (n(:));
    p = cumsum (hygepdf (v, t(ok), m(ok), n, "vectorexpand"), 2);

    ## manual row-wise vectorization of lookup, which returns index of element
    ## less than or equal to test value, zero if test value is less than lowest
    ## number, and max index if greater than highest number.

    end_locs = sub2ind (size (p), [1 : num_n]', n(:) + 1);
    p = (p ./ p(end_locs)) - rand (num_n, 1);
    p(p>=0) = NaN;  #NaN values ignored by max
    [p_match, p_match_idx] = max (p, [], 2);
    p_match_idx(isnan(p_match)) = 0; #rand < min(p) gives NaN, reset to 0
    rnd(ok) = v(p_match_idx + 1);
  endif

endfunction


%!assert (size (hygernd (4,2,2)), [1, 1])
%!assert (size (hygernd (4*ones (2,1), 2,2)), [2, 1])
%!assert (size (hygernd (4*ones (2,2), 2,2)), [2, 2])
%!assert (size (hygernd (4, 2*ones (2,1), 2)), [2, 1])
%!assert (size (hygernd (4, 2*ones (2,2), 2)), [2, 2])
%!assert (size (hygernd (4, 2, 2*ones (2,1))), [2, 1])
%!assert (size (hygernd (4, 2, 2*ones (2,2))), [2, 2])
%!assert (size (hygernd (4, 2, 2, 3)), [3, 3])
%!assert (size (hygernd (4, 2, 2, [4 1])), [4, 1])
%!assert (size (hygernd (4, 2, 2, 4, 1)), [4, 1])

%!assert (class (hygernd (4,2,2)), "double")
%!assert (class (hygernd (single (4),2,2)), "single")
%!assert (class (hygernd (single ([4 4]),2,2)), "single")
%!assert (class (hygernd (4,single (2),2)), "single")
%!assert (class (hygernd (4,single ([2 2]),2)), "single")
%!assert (class (hygernd (4,2,single (2))), "single")
%!assert (class (hygernd (4,2,single ([2 2]))), "single")

## Test input validation
%!error hygernd ()
%!error hygernd (1)
%!error hygernd (1,2)
%!error hygernd (ones (3), ones (2), ones (2), 2)
%!error hygernd (ones (2), ones (3), ones (2), 2)
%!error hygernd (ones (2), ones (2), ones (3), 2)
%!error hygernd (i, 2, 2)
%!error hygernd (2, i, 2)
%!error hygernd (2, 2, i)
%!error hygernd (4,2,2, -1)
%!error hygernd (4,2,2, ones (2))
%!error hygernd (4,2,2, [2 -1 2])
%!error hygernd (4*ones (2),2,2, 3)
%!error hygernd (4*ones (2),2,2, [3, 2])
%!error hygernd (4*ones (2),2,2, 3, 2)
