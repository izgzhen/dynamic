-- Common: Commonly useful utilities
{-# LANGUAGE PolyKinds #-}

module Common where

import Control.Monad.Except
import qualified Data.Map as M

lookupM :: (MonadError String m, Show k, Ord k) => k -> M.Map k v -> m v
lookupM k m = case M.lookup k m of
    Just v  -> return v
    Nothing -> throwError $ "Can't find " ++ show k

data Proxy t = Proxy
