-- Abstract: Abstract the essentials out of value
module Core.Abstract where

class Eq a => Lattice a where
    join :: a -> a -> a
    meet :: a -> a -> a
    top  :: a
    bot  :: a

    -- default implementation for a flat lattice
    join a b | a == b = a
             | a /= b = top
    meet a b | a == b = a
             | a /= b = bot

-- Homomorphism
class Hom a b where
    hom :: a -> b

-- Monomorphic reduction
class Reduce a op where
    reduce :: op -> a -> a -> a
