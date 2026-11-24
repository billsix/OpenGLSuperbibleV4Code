"""Triangle normals and plane equations for the shadow and lit-mesh demos.

A frozen copy of ``find_normal`` and ``plane_equation`` from ``mathutils.py``
in ``github.com/billsix/modelviewprojection``; the demos use no other function
from that module. The copy keeps this repository independent of the course
repository. The vectors are ``gacalc.g3.Vector`` from
``github.com/billsix/geometricalgebra``.

Both functions use counter-clockwise winding, matching OpenGL's ``GL_CCW``
front face.
"""

import typing

import gacalc.g3 as g3


def find_normal(p1: g3.Vector, p2: g3.Vector, p3: g3.Vector) -> g3.Vector:
    """Return the surface normal of the triangle ``(p1, p2, p3)``.

    The result is the cross product of the two edge vectors, so its length is
    twice the triangle's area; normalize it for a unit normal.

    Args:
        p1: First vertex.
        p2: Second vertex.
        p3: Third vertex.

    Returns:
        The unnormalized normal, pointing out of a counter-clockwise face.
    """
    return (p2 - p1).cross(p3 - p1)


def plane_equation(
    p1: g3.Vector, p2: g3.Vector, p3: g3.Vector
) -> typing.Tuple[g3.Vector, float]:
    """Return the plane through three points as ``(normal, d)``.

    Every point ``P`` on the plane satisfies ``normal . P + d == 0``. The
    normal is a unit vector and ``d`` is the negated signed distance from the
    origin along it.

    Args:
        p1: First point, wound counter-clockwise with the other two.
        p2: Second point.
        p3: Third point.

    Returns:
        The unit normal and the offset ``d``.
    """
    n: g3.Vector = find_normal(p1, p2, p3)
    inv_len: float = 1.0 / float(abs(n))
    n_unit: g3.Vector = g3.Vector(
        coeff_e_1=float(n.coeff_e_1) * inv_len,
        coeff_e_2=float(n.coeff_e_2) * inv_len,
        coeff_e_3=float(n.coeff_e_3) * inv_len,
    )
    d: float = float(-n_unit.dot(p1).scalar_part())
    return (n_unit, d)
