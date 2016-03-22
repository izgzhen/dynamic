{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, FlexibleContexts #-}

module Flow where

import Data.Set (Set)

class Label a => Flow ast a where
    initLabel :: ast a -> a
    finalLabels :: ast a -> Set a
    flow :: ast a -> Set (a, a)

class Ord a => Label a where