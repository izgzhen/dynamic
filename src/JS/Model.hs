-- Model: Execution Model

{-# LANGUAGE TemplateHaskell #-}
module JS.Model (
  Env(..), initEnv, Value(..),
  ScopeChain(..), CallString,
  Object(..), Ref(..),
  storeObj, unionRef, unionStore, updateObj,
  bindValue, unionEnv, valToPlatExpr
) where

import Core.Abstract
import JS.AST
import JS.Type
import JS.Platform (JsExpr(..), JsVal(..))

import qualified Data.Map as M

-- Call String: Context Sensitivity

type CallString label = [label]

-- Scope Chain: Closure capturing

data ScopeChain label = TopLevel
                      | Enclosed label -- construction site
                                 label -- closure label
                                 (ScopeChain label) -- father chain
                      deriving (Show, Eq, Ord)

-- Value Model

newtype Ref = Ref Int deriving (Show, Eq, Ord)

incrRef :: Ref -> Ref
incrRef (Ref i) = Ref (i + 1)

initRef :: Ref
initRef = Ref 0

data Value a p = VPrim p
               | VRef Ref
               | VPlat Name
               | VPlatRef JRef
               | VTop -- FIXME: Can be anything .... which is too coarse
               deriving (Show, Eq)

data Object a p = Object (M.Map Name (Value a p))
                -- FIXME: Actually, [Function] is also an object ... but we don't model this temporarily
                | OClos (ScopeChain a) (CallString a) [Name] (Stmt a)
                | OTop -- FIXME: ...
                deriving (Show, Eq)

-- Environment

type Bindings a p = M.Map Name (Value a p)
type Store    a p = M.Map Ref  (Object a p) -- XXX: Store => Heap

data Env a p = Env {
    _bindings :: Bindings a p,
    _store    :: Store a p,
    _refCount :: Ref,
    _catcher  :: Maybe (a, Name)
} deriving (Eq)

instance (Show a, Show p) => Show (Env a p) where
    show env = "refCount: " ++ show (_refCount env) ++ "\n" ++
               "catcher: " ++ show (_catcher env) ++ "\n" ++
               "bindings:\n" ++ concatMap (\(Name x, v) -> x ++ "\t" ++ show v ++ "\n") (M.toList (_bindings env)) ++
               "store:\n" ++ concatMap (\(Ref i, o) -> show i ++ "\t" ++ show o ++ "\n") (M.toList (_store env))

initEnv :: Env a p
initEnv = Env M.empty M.empty initRef Nothing

bindValue :: Name -> Value a p -> Env a p -> Env a p
bindValue x v env = env { _bindings = M.insert x v (_bindings env) }

storeObj :: Object a p -> Env a p -> (Env a p, Ref)
storeObj o env =
    let ref = _refCount env
    in  (env { _store    = M.insert ref o (_store env),
               _refCount = incrRef ref }, ref)

updateObj :: Ref -> Object a p -> Env a p -> Env a p
updateObj r o env = env { _store = M.insert r o (_store env) }


-- Lattice Model
-- FIXME: Implement the Lattice type-class

-- NOTE: directional union
unionEnv :: (Eq a, Lattice p) => Env a p -> Env a p -> Env a p
unionEnv (Env b1 s1 rc1 c) (Env b2 s2 rc2 _) =
    Env (b1 `unionBindings` b2) (s1 `unionStore` s2) (rc1 `unionRef` rc2) c

unionBindings :: Lattice p => Bindings a p -> Bindings a p -> Bindings a p
unionBindings = M.unionWith unionValue

unionStore :: (Eq a, Eq p) => Store a p -> Store a p -> Store a p
unionStore = M.unionWith unionObject

unionValue :: Lattice p => Value a p -> Value a p -> Value a p
unionValue (VPrim p1) (VPrim p2) = VPrim $ join p1 p2
unionValue v1 v2 = if v1 == v2 then v1 else VTop -- FIXME: Wow, Magic!

unionObject :: (Eq a, Eq p) => Object a p -> Object a p -> Object a p
unionObject o1 o2 = if o1 == o2 then o1 else OTop -- FIXME: Wow, So Magic!

unionRef :: Ref -> Ref -> Ref
unionRef (Ref i1) (Ref _i2) = Ref i1 -- FIXME: Seriously?

valToPlatExpr :: Hom p Prim => Value a p -> JsExpr
valToPlatExpr (VPrim p)    = JVal (JVPrim (hom p :: Prim))
valToPlatExpr (VPlatRef r) = JVal (JVRef r)
