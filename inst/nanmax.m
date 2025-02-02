## Copyright (C) 2001 Paul Kienzle <pkienzle@users.sf.net>
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {[@var{v}, @var{idx}] =} nanmax (@var{X})
## @deftypefnx{Function File} {[@var{v}, @var{idx}] =} nanmax (@var{X}, @var{Y})
## Find the maximal element while ignoring NaN values.
##
## @code{nanmax} is identical to the @code{max} function except that NaN values
## are ignored.  If all values in a column are NaN, the maximum is 
## returned as NaN rather than []. 
##
## @seealso{max, nansum, nanmin, nanmean, nanmedian}
## @end deftypefn

function [v, idx] = nanmax (X, Y, DIM)
  if nargin < 1 || nargin > 3
    print_usage;
  elseif nargin == 1 || (nargin == 2 && isempty(Y))
    nanvals = isnan(X);
    X(nanvals) = -Inf;
    [v, idx] = max (X);
    v(all(nanvals)) = NaN;
  elseif (nargin == 3 && isempty(Y))
    nanvals = isnan(X);
    X(nanvals) = -Inf;
    [v, idx] = max (X,[],DIM);
    v(all(nanvals,DIM)) = NaN;
  else
    Xnan = isnan(X);
    Ynan = isnan(Y);
    X(Xnan) = -Inf;
    Y(Ynan) = -Inf;
    if (nargin == 3)
      [v, idx] = max(X,Y,DIM);
    else
      [v, idx] = max(X,Y);
    endif
    v(Xnan & Ynan) = NaN;
  endif
endfunction

%!assert (nanmax ([2 4 NaN 7]), 7)
%!assert (nanmax ([2 4 NaN Inf]), Inf)
%!assert (nanmax ([1 NaN 3; NaN 5 6; 7 8 NaN]), [7, 8, 6])
%!assert (nanmax ([1 NaN 3; NaN 5 6; 7 8 NaN]'), [3, 6, 8])
%!assert (nanmax (single ([1 NaN 3; NaN 5 6; 7 8 NaN])), single ([7 8 6]))