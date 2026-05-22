import SpriteKit

struct AttackCone {

    static func path(
        origin: CGPoint,
        direction: CGVector,
        range: CGFloat,
        angle: CGFloat
    ) -> CGPath {
        let directionAngle = atan2(direction.dy, direction.dx)
        let startAngle = directionAngle - angle / 2
        let endAngle = directionAngle + angle / 2

        let path = CGMutablePath()
        path.move(to: origin)

        let steps = 16
        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let currentAngle = startAngle + (endAngle - startAngle) * progress

            path.addLine(to: CGPoint(
                x: origin.x + cos(currentAngle) * range,
                y: origin.y + sin(currentAngle) * range
            ))
        }

        path.closeSubpath()
        return path
    }

    static func contains(
        point: CGPoint,
        pointRadius: CGFloat,
        origin: CGPoint,
        direction: CGVector,
        range: CGFloat,
        angle: CGFloat
    ) -> Bool {
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        let distance = sqrt(dx * dx + dy * dy)

        guard distance > 0 else {
            return false
        }

        if distance > range + pointRadius {
            return false
        }

        let pointDirection = CGVector(dx: dx / distance, dy: dy / distance)
        let dot = direction.dx * pointDirection.dx + direction.dy * pointDirection.dy
        let angleToPoint = acos(max(-1, min(1, dot)))

        let angleMargin = atan2(pointRadius, distance)
        let allowedAngle = angle / 2 + angleMargin

        return angleToPoint <= allowedAngle
    }
}
