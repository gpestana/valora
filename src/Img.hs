{-# LANGUAGE MultiParamTypeClasses #-}

module Img
  ( Raster
  , Layer
  , newLayer
  , RGBA
  ) where

import Data.Array.Repa (Array, DIM2, DIM3, Z(..), (:.)(..))
import qualified Data.Array.Repa as R
import Data.Word (Word8)

type Raster = Array R.U DIM2 Dot

type Dot = (Word8, Word8, Word8)

type RGBA = (Double, Double, Double, Double)

type Layer = Array R.D DIM2 RGBA

newLayer :: (Int, Int) -> Layer
newLayer (w, h) = R.traverse (raw (w, h)) packDims packPixel
  where
    packDims (Z :. w :. h :. c) = (Z :. w :. h)
    packPixel indx (Z :. x :. y) =
      ( indx (Z :. x :. y :. 0)
      , indx (Z :. x :. y :. 1)
      , indx (Z :. x :. y :. 2)
      , indx (Z :. x :. y :. 3))

applyLayer :: Layer -> Layer -> Layer
applyLayer bottom top = R.traverse bottom id applyPixelProxy
  where
    applyPixelProxy indx pos = applyPixel (indx pos) (top R.! pos)

raw :: (Int, Int) -> Array R.U DIM3 Double
raw (w, h) = R.fromListUnboxed (Z :. w :. h :. 4) (take (w * h * 4) (cycle [0]))

applyPixel (br, bg, bb, ba) (tr, tg, tb, ta) = (fc br tr, fc bg tg, fc bb tb, denom)
  where
    denom = ta + tb * (1 - ta)
    fc b t = ta * t + ba * b * (1 - ta) / (ta + tb * (1 - ta))

rasterPixel (r, g, b, _) = (f r, f g, f b)
  where
    f = floor . (* 255)
