// lib/widgets/task_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/task.dart';
// O import do location_service.dart não é mais necessário aqui,
// pois o roteiro não o utiliza neste arquivo.

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(bool?) onCheckboxChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    required this.onCheckboxChanged,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber; // Alterado para 'amber' para melhor diferenciação
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.arrow_upward;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.arrow_downward;
      default:
        return Icons.flag;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      case 'low':
        return 'Baixa';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.completed 
            ? Colors.grey.shade300 
            : priorityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.completed,
                    onChanged: onCheckboxChanged,
                    activeColor: Colors.green,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                            color: task.completed 
                              ? Colors.grey 
                              : Colors.black87,
                          ),
                        ),

                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: task.completed 
                                ? Colors.grey 
                                : Colors.black54,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // --- NOVA SEÇÃO DE BADGES ---
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Badge: Prioridade
                            _buildBadge(
                              _getPriorityIcon(),
                              _getPriorityLabel(),
                              priorityColor,
                            ),

                            // Badge: Foto
                            if (task.hasPhoto)
                              _buildBadge(
                                Icons.photo_camera,
                                'Foto',
                                Colors.blue,
                              ),

                            // Badge: Localização
                            if (task.hasLocation)
                              _buildBadge(
                                Icons.location_on,
                                'Local',
                                Colors.purple,
                              ),

                            // Badge: Concluída por Shake
                            if (task.completed && task.wasCompletedByShake)
                              _buildBadge(
                                Icons.vibration,
                                'Shake',
                                Colors.green,
                              ),
                            
                            // Badge: Não Sincronizada
                            if (!task.isSynced)
                              _buildBadge(
                                Icons.cloud_off,
                                'Pendente',
                                Colors.grey,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Deletar',
                  ),
                ],
              ),
            ),

            // PREVIEW DA FOTO
            if (task.hasPhoto)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.file(
                  File(task.photoPath!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Widget para caso a foto tenha sido apagada
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Foto não encontrada',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os Badges
  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}