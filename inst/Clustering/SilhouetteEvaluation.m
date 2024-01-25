## Copyright (C) 2021 Stefano Guidoni <ilguido@users.sf.net>
## Copyright (C) 2024 Andreas Bertsatos <abertsatos@biol.uoa.gr>
##
## This file is part of the statistics package for GNU Octave.
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

classdef SilhouetteEvaluation < ClusterCriterion
  ## -*- texinfo -*-
  ## @deftypefn {Function File} {@var{eva} =} evalclusters (@var{x}, @var{clust}, @qcode{silhouette})
  ## @deftypefnx {Function File} {@var{eva} =} evalclusters (@dots{}, @qcode{Name}, @qcode{Value})
  ##
  ## A silhouette object to evaluate clustering solutions.
  ##
  ## A @code{SilhouetteEvaluation} object is a @code{ClusterCriterion}
  ## object used to evaluate clustering solutions using the silhouette
  ## criterion.
  ##
  ## List of public properties specific to @code{SilhouetteEvaluation}:
  ## @table @code
  ## @item @qcode{Distance}
  ## a valid distance metric name, or a function handle or a numeric array as
  ## generated by the @code{pdist} function.
  ##
  ## @item @qcode{ClusterPriors}
  ## a valid name for the evaluation of silhouette values: @code{empirical}
  ## (default) or @code{equal}.
  ##
  ## @item @qcode{ClusterSilhouettes}
  ## a cell array with the silhouette values of each data point for each cluster
  ## number.
  ##
  ## @end table
  ##
  ## The best solution according to the silhouette criterion is the one
  ## that scores the highest average silhouette value.
  ## @end deftypefn
  ##
  ## @seealso{evalclusters, ClusterCriterion, CalinskiHarabaszEvaluation,
  ## DaviesBouldinEvaluation, GapEvaluation}}

  properties (GetAccess = public, SetAccess = private)
    Distance = "";           # pdist parameter
    ClusterPriors = "";      # evaluation of silhouette values: equal or empirical
    ClusterSilhouettes = {}; # results of the silhoutte function for each K
  endproperties

  properties (Access = protected)
    DistanceVector = [];     # vector of pdist distances
  endproperties

  methods (Access = public)

    ## constructor
    function this = SilhouetteEvaluation (x, clust, KList, ...
                    distanceMetric = "sqeuclidean", clusterPriors = "empirical")
      this@ClusterCriterion(x, clust, KList);

      ## parsing the distance criterion
      if (ischar (distanceMetric))
        if (any (strcmpi (distanceMetric, {"sqeuclidean", ...
                  "euclidean", "cityblock", "cosine", "correlation", ...
                  "hamming", "jaccard"})))
          this.Distance = lower (distanceMetric);

          ## kmeans can use only a subset
          if (strcmpi (clust, "kmeans") && any (strcmpi (this.Distance, ...
              {"euclidean", "jaccard"})))
            error (["SilhouetteEvaluation: invalid distance criterion '%s' "...
                    "for 'kmeans'"], distanceMetric);
          endif
        else
          error ("SilhouetteEvaluation: unknown distance criterion '%s'", ...
                 distanceMetric);
        endif
      elseif (isa (distanceMetric, "function_handle"))
        this.Distance = distanceMetric;

        ## kmeans cannot use a function handle
        if (strcmpi (clust, "kmeans"))
          error (["SilhouetteEvaluation: invalid distance criterion for "...
                  "'kmeans'"]);
        endif
      elseif (isvector (distanceMetric) && isnumeric (distanceMetric))
        this.Distance = "";
        this.DistanceVector = distanceMetric; # the validity check is delegated

        ## kmeans cannot use a distance vector
        if (strcmpi (clust, "kmeans"))
          error (["SilhouetteEvaluation: invalid distance criterion for "...
                  "'kmeans'"]);
        endif
      else
        error ("SilhouetteEvaluation: invalid distance metric");
      endif

      ## parsing the prior probabilities of each cluster
      if (ischar (distanceMetric))
        if (any (strcmpi (clusterPriors, {"empirical", "equal"})))
          this.ClusterPriors = lower (clusterPriors);
        else
          error (["SilhouetteEvaluation: unknown prior probability criterion"...
                 " '%s'"], clusterPriors);
        endif
      else
        error ("SilhouetteEvaluation: invalid prior probabilities");
      endif

      this.CriterionName = "silhouette";
      this.evaluate(this.InspectedK); # evaluate the list of cluster numbers
    endfunction

    ## -*- texinfo -*-
    ## @deftypefn {SilhouetteEvaluation} {@var{obj} =} addK (@var{obj}, @var{K})
    ##
    ## Add a new cluster array to inspect the SilhouetteEvaluation object.
    ##
    ## @end deftypefn
    function this = addK (this, K)
      addK@ClusterCriterion(this, K);

      ## if we have new data, we need a new evaluation
      if (this.OptimalK == 0)
        ClusterSilhouettes_tmp = {};
        pS = 0; # position shift of the elements of ClusterSilhouettes
        for iter = 1 : length (this.InspectedK)
          ## reorganize ClusterSilhouettes according to the new list
          ## of cluster numbers
          if (any (this.InspectedK(iter) == K))
            pS += 1;
          else
            ClusterSilhouettes_tmp{iter} = this.ClusterSilhouettes{iter - pS};
          endif
        endfor
        this.ClusterSilhouettes = ClusterSilhouettes_tmp;
        this.evaluate(K); # evaluate just the new cluster numbers
      endif
    endfunction

    ## -*- texinfo -*-
    ## @deftypefn  {SilhouetteEvaluation} {} plot (@var{obj})
    ## @deftypefnx {SilhouetteEvaluation} {@var{h} =} plot (@var{obj})
    ##
    ## Plot the evaluation results.
    ##
    ## Plot the CriterionValues against InspectedK from the
    ## SilhouetteEvaluation ClusterCriterion, @var{obj}, to the current plot.
    ## It can also return a handle to the current plot.
    ##
    ## @end deftypefn
    function h = plot (this)
      yLabel = sprintf ("%s value", this.CriterionName);
      h = gca ();
      hold on;
      plot (this.InspectedK, this.CriterionValues, "bo-");
      plot (this.OptimalK, this.CriterionValues(this.OptimalIndex), "b*");
      xlabel ("number of clusters");
      ylabel (yLabel);
      hold off;
    endfunction

    ## -*- texinfo -*-
    ## @deftypefn {SilhouetteEvaluation} {@var{eva} =} compact (@var{obj})
    ##
    ## Return a compact SilhouetteEvaluation object (not implemented yet).
    ##
    ## @end deftypefn
    function this = compact (this)
      warning (["SilhouetteEvaluation.compact: this"...
                " method is not yet implemented."]);
    endfunction

  endmethods

  methods (Access = protected)
    ## evaluate
    ## do the evaluation
    function this = evaluate (this, K)
      ## use complete observations only
      UsableX = this.X(find (this.Missing == false), :);
      if (! isempty (this.ClusteringFunction))
        ## build the clusters
        for iter = 1 : length (this.InspectedK)
          ## do it only for the specified K values
          if (any (this.InspectedK(iter) == K))
            if (isa (this.ClusteringFunction, "function_handle"))
              ## custom function
              ClusteringSolution = ...
                this.ClusteringFunction(UsableX, this.InspectedK(iter));
              if (ismatrix (ClusteringSolution) && ...
                  rows (ClusteringSolution) == this.NumObservations && ...
                  columns (ClusteringSolution) == this.P)
                ## the custom function returned a matrix:
                ## we take the index of the maximum value for every row
                [~, this.ClusteringSolutions(:, iter)] = ...
                  max (ClusteringSolution, [], 2);
              elseif (iscolumn (ClusteringSolution) &&
                      length (ClusteringSolution) == this.NumObservations)
                this.ClusteringSolutions(:, iter) = ClusteringSolution;
              elseif (isrow (ClusteringSolution) &&
                      length (ClusteringSolution) == this.NumObservations)
                this.ClusteringSolutions(:, iter) = ClusteringSolution';
              else
                error (["SilhouetteEvaluation: invalid return value from " ...
                        "custom clustering function"]);
              endif
              this.ClusteringSolutions(:, iter) = ...
                this.ClusteringFunction(UsableX, this.InspectedK(iter));
            else
              switch (this.ClusteringFunction)
                case "kmeans"
                  this.ClusteringSolutions(:, iter) = kmeans (UsableX, ...
                    this.InspectedK(iter), "Distance", this.Distance, ...
                    "EmptyAction", "singleton", "Replicates", 5);

                case "linkage"
                  if (! isempty (this.Distance))
                    ## use clusterdata
                    Distance_tmp = this.Distance;
                    LinkageMethod = "average"; # for non euclidean methods
                    if (strcmpi (this.Distance, "sqeuclidean"))
                      ## pdist uses different names for its algorithms
                      Distance_tmp = "squaredeuclidean";
                      LinkageMethod = "ward";
                    elseif (strcmpi (this.Distance, "euclidean"))
                      LinkageMethod = "ward";
                    endif
                    this.ClusteringSolutions(:, iter) = clusterdata (UsableX,...
                      "MaxClust", this.InspectedK(iter), ...
                      "Distance", Distance_tmp, "Linkage", LinkageMethod);
                  else
                    ## use linkage
                    Z = linkage (this.DistanceVector, "average");
                    this.ClusteringSolutions(:, iter) = ...
                         cluster (Z, "MaxClust", this.InspectedK(iter));
                  endif

                case "gmdistribution"
                  gmm = fitgmdist (UsableX, this.InspectedK(iter), ...
                        "SharedCov", true, "Replicates", 5);
                  this.ClusteringSolutions(:, iter) = cluster (gmm, UsableX);

                otherwise
                  error (["SilhouetteEvaluation: unexpected error, " ...
                         "report this bug"]);
              endswitch
            endif
          endif
        endfor
      endif

      ## get the silhouette values for every clustering
      set (0, 'DefaultFigureVisible', 'off'); # temporarily disable figures
      for iter = 1 : length (this.InspectedK)
        ## do it only for the specified K values
        if (any (this.InspectedK(iter) == K))
          this.ClusterSilhouettes{iter} = silhouette (UsableX, ...
                                            this.ClusteringSolutions(:, iter));
          if (strcmpi (this.ClusterPriors, "empirical"))
            this.CriterionValues(iter) = mean (this.ClusterSilhouettes{iter});
          else
            ## equal
            this.CriterionValues(iter) = 0;
            si = this.ClusterSilhouettes{iter};
            for k = 1 : this.InspectedK(iter)
              this.CriterionValues(iter) += mean (si(find ...
                                     (this.ClusteringSolutions(:, iter) == k)));
            endfor
            this.CriterionValues(iter) /= this.InspectedK(iter);
          endif
        endif
      endfor
      set (0, 'DefaultFigureVisible', 'on'); # enable figures again

      [~, this.OptimalIndex] = max (this.CriterionValues);
      this.OptimalK = this.InspectedK(this.OptimalIndex(1));
      this.OptimalY = this.ClusteringSolutions(:, this.OptimalIndex(1));
    endfunction
  endmethods
endclassdef
